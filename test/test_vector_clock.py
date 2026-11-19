"""Unit tests for vector clock causality."""
import unittest

class TestVectorClockCausality(unittest.TestCase):
    def test_concurrent_clock_detection(self):
        clock_a = {'node_1': 2, 'node_2': 1}
        clock_b = {'node_1': 1, 'node_2': 2}
        is_a_greater = all(clock_a[k] >= clock_b[k] for k in clock_a)
        is_b_greater = all(clock_b[k] >= clock_a[k] for k in clock_a)
        is_concurrent = (not is_a_greater) and (not is_b_greater)
        self.assertTrue(is_concurrent)

if __name__ == '__main__':
    unittest.main()
