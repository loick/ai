import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('watch', Path(__file__).with_name('watch.py'))
watch = importlib.util.module_from_spec(spec)
spec.loader.exec_module(watch)


class WatchTests(unittest.TestCase):
    def test_paginates_every_comment_collection(self):
        pull = {'merged_at': None, 'state': 'open', 'head': {'sha': 'abc'}}
        pages = [[{'id': 1, 'body': 'first'}], [{'id': 2, 'body': 'last'}]]
        with patch.object(watch, 'gh', side_effect=[pull, pages, pages, pages]) as gh:
            terminal, comments = watch.snapshot('owner', 'repo', '1')
        self.assertIsNone(terminal)
        self.assertEqual(len(comments), 6)
        self.assertEqual(comments['inline:2']['comment']['body'], 'last')
        for call in gh.call_args_list[1:]:
            self.assertIn('--paginate', call.args)
            self.assertIn('--slurp', call.args)

    def test_first_observation_edits_and_new_heads(self):
        comments = {'inline:1': {'kind': 'inline', 'comment': {'id': 1, 'body': 'fix'}, 'head': 'a'}}
        changed, seen = watch.events(comments, {})
        self.assertEqual(len(changed), 1)
        comments['inline:1']['head'] = 'b'
        self.assertEqual(watch.events(comments, seen)[0], [])
        comments['inline:1']['comment']['body'] = 'different finding'
        self.assertEqual(len(watch.events(comments, seen)[0]), 1)

    def test_merge_and_closure_are_terminal_before_comment_reads(self):
        for merged_at, state, kind in [('today', 'closed', 'merged'), (None, 'closed', 'closed')]:
            with self.subTest(kind=kind):
                pull = {'merged_at': merged_at, 'state': state, 'html_url': 'url'}
                with patch.object(watch, 'gh', return_value=pull) as gh:
                    terminal, comments = watch.snapshot('o', 'r', '1')
                self.assertEqual(terminal['kind'], kind)
                self.assertEqual(comments, {})
                self.assertEqual(gh.call_count, 1)

    def test_restart_does_not_replay_delivered_events(self):
        comments = {'comment:1': {'kind': 'comment', 'comment': {'id': 1, 'body': 'hello'}, 'head': 'a'}}
        with tempfile.TemporaryDirectory() as tmp:
            with patch.object(watch.Path, 'home', return_value=Path(tmp)):
                for expected in [1, 0]:
                    output = io.StringIO()
                    with patch.object(watch, 'snapshot', return_value=(None, comments)):
                        with patch('sys.stdout', output):
                            watch.watch('https://github.com/o/r/pull/1', once=True)
                    events = [json.loads(line) for line in output.getvalue().splitlines()]
                    self.assertEqual(sum(e['kind'] == 'comment' for e in events), expected)
                state = Path(tmp) / '.local/state/ai/pr-feedback/o/r/1/watch.json'
                self.assertEqual(state.stat().st_mode & 0o777, 0o600)

    def test_api_failure_does_not_acknowledge_events(self):
        with tempfile.TemporaryDirectory() as tmp:
            with patch.object(watch.Path, 'home', return_value=Path(tmp)):
                with patch.object(watch, 'snapshot', side_effect=subprocess.CalledProcessError(1, ['gh'])):
                    with patch('sys.stdout', io.StringIO()):
                        with self.assertRaises(subprocess.CalledProcessError):
                            watch.watch('https://github.com/o/r/pull/1', once=True)
                self.assertFalse(list(Path(tmp).rglob('watch.json')))

    def test_rejects_invalid_or_non_github_urls(self):
        for value in ['1', 'https://example.com/o/r/pull/1', 'https://github.com/o/r/pull/0']:
            with self.subTest(value=value), self.assertRaises(ValueError):
                watch.identity(value)


if __name__ == '__main__':
    unittest.main()
