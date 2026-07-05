"""Tests for dogfood.py."""
import unittest
from dogfood import count_by_field, summarize_status


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


class TestCountByField(unittest.TestCase):
    def test_basic(self):
        items = [{"k": "a"}, {"k": "b"}, {"k": "a"}]
        self.assertEqual(count_by_field(items, "k"), {"a": 2, "b": 1})

    def test_empty_list(self):
        self.assertEqual(count_by_field([], "k"), {})

    def test_missing_field_key(self):
        items = [{"k": "a"}, {"other": "x"}, {"k": "a"}]
        self.assertEqual(count_by_field(items, "k"), {"a": 2, None: 1})

    def test_none_field_value(self):
        items = [{"k": "a"}, {"k": None}, {"k": "b"}]
        self.assertEqual(count_by_field(items, "k"), {"a": 1, None: 1, "b": 1})

    def test_missing_and_none_same_bucket(self):
        items = [{"k": "a"}, {"other": "x"}, {"k": None}, {"k": "a"}]
        self.assertEqual(count_by_field(items, "k"), {"a": 2, None: 2})


if __name__ == "__main__":
    unittest.main()
