"""Tests for summarize_status()."""
import unittest
from dogfood import summarize_status


class TestSummarizeStatus(unittest.TestCase):
    def test_basic(self):
        items = [{"status": "PASS"}, {"status": "FAIL"}, {"status": "PASS"}]
        self.assertEqual(summarize_status(items), {"PASS": 2, "FAIL": 1})

    def test_empty_list(self):
        self.assertEqual(summarize_status([]), {})

    def test_single_item(self):
        self.assertEqual(summarize_status([{"status": "OK"}]), {"OK": 1})

    def test_missing_status_key_ignored(self):
        items = [{"status": "PASS"}, {"name": "no-status"}, {"status": "PASS"}]
        self.assertEqual(summarize_status(items), {"PASS": 2})

    def test_none_status_ignored(self):
        items = [{"status": "PASS"}, {"status": None}, {"status": "FAIL"}]
        self.assertEqual(summarize_status(items), {"PASS": 1, "FAIL": 1})

    def test_multiple_statuses(self):
        items = [
            {"status": "PASS"},
            {"status": "FAIL"},
            {"status": "SKIP"},
            {"status": "PASS"},
            {"status": "SKIP"},
        ]
        self.assertEqual(summarize_status(items), {"PASS": 2, "FAIL": 1, "SKIP": 2})


if __name__ == "__main__":
    unittest.main()
