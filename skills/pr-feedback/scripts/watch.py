#!/usr/bin/env python3
"""Read-only PR comment watcher; workflow decisions live in decisions.json."""

import argparse
import fcntl
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import time
from urllib.parse import urlparse


def gh(*args):
    result = subprocess.run(
        ['gh', *args], capture_output=True, text=True, timeout=60, check=True
    )
    return json.loads(result.stdout)


def identity(reference):
    url = urlparse(reference)
    match = re.fullmatch(r'/([\w.-]+)/([\w.-]+)/pull/([1-9]\d*)/?', url.path)
    if url.scheme != 'https' or url.hostname != 'github.com' or not match:
        raise ValueError('Expected https://github.com/OWNER/REPO/pull/NUMBER')
    return match.groups()


def snapshot(owner, repo, number):
    pull = gh('api', f'repos/{owner}/{repo}/pulls/{number}')
    if pull['merged_at']:
        return {'kind': 'merged', 'url': pull['html_url']}, {}
    if pull['state'] == 'closed':
        return {'kind': 'closed', 'url': pull['html_url']}, {}
    comments = {}
    for kind, route in [
        ('comment', f'issues/{number}/comments'),
        ('inline', f'pulls/{number}/comments'),
        ('review', f'pulls/{number}/reviews'),
    ]:
        pages = gh('api', f'repos/{owner}/{repo}/{route}?per_page=100', '--paginate', '--slurp')
        for page in pages:
            for comment in page:
                if not comment.get('body', '').strip():
                    continue
                comments[f'{kind}:{comment["id"]}'] = {
                    'kind': kind, 'comment': comment, 'head': pull['head']['sha']
                }
    return None, comments


def events(comments, seen):
    changed = []
    fingerprints = {}
    for key, value in comments.items():
        # A new commit alone must not replay every comment.
        digest = hashlib.sha256(json.dumps(value['comment'], sort_keys=True).encode()).hexdigest()
        fingerprints[key] = digest
        if seen.get(key) != digest:
            changed.append(value)
    return changed, fingerprints


def save(path, data):
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(data))
    temporary.chmod(0o600)
    temporary.replace(path)


def emit(event):
    print(json.dumps(event), flush=True)


def watch(reference, once=False):
    owner, repo, number = identity(reference)
    directory = Path.home() / '.local/state/ai/pr-feedback' / owner / repo / number
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    state = directory / 'watch.json'
    with (directory / 'watch.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        seen = json.loads(state.read_text()) if state.exists() else {}
        emit({'kind': 'started', 'state_directory': str(directory)})
        while True:
            terminal, comments = snapshot(owner, repo, number)
            if terminal:
                emit(terminal)
                return
            changed, fingerprints = events(comments, seen)
            for event in changed:
                emit(event)
            save(state, fingerprints)
            seen = fingerprints
            if once:
                return
            time.sleep(30)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('pr', help='Full GitHub PR URL')
    parser.add_argument('--once', action='store_true', help='Read once without waiting')
    args = parser.parse_args()
    try:
        watch(args.pr, args.once)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        detail = error.stderr if isinstance(error, subprocess.CalledProcessError) else str(error)
        emit({'kind': 'error', 'message': detail})
        return 1
    except KeyboardInterrupt:
        return 130
    return 0


if __name__ == '__main__':
    sys.exit(main())
