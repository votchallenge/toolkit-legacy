Analysis module
===============

The analysis module contains functions related to performance analysis and general analysis of results. The core of the module
is a ranking methodology that is based on Accuracy-Robustness measure pair, proposed in [this paper].


Module functions
----------------

### Performance measures

-    [estimate_accuracy](estimate_accuracy.m) - Calculate accuracy score
-    [estimate_failures](estimate_failures.m) - Computes number of failures score
-    [estimate_expected_overlap](estimate_expected_overlap.m) - Estimates expected average overlap for different sequence lengths

### Ranking

-    [compare_trackers](compare_trackers.m) - Compares two trackers in terms of accuracy and robustness
-    [adapted_ranks](adapted_ranks.m) - Performs rank adaptation on a set of ranks
-    [analyze_ranks](analyze_ranks.m) - Performs ranking analysis on per-sequence or per-label basis
-    [create_label_selectors](create_label_selectors.m) - Create per-label selectors
-    [create_sequence_selectors](create_sequence_selectors.m) - Create per-sequence selectors

### Speed

-    [normalize_speed](normalize_speed.m) - Normalizes tracker speed estimate
-    [analyze_speed](analyze_speed.m) - Perform speed analysis

### Other analyses

-    [analyze_expected_overlap](analyze_expected_overlap.m) - Performs expected overlap analysis
-    [analyze_failures](analyze_failures.m) - Perform failure frequency analysis


[this paper]: http://prints.vicos.si/publications/302/  "Is my new tracker really better than yours?"
