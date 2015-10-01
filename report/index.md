Reporting module
================

This module contains functions used in generation of reports and visualizations. Most reports rely on report context structure that provides a simple mechanism to generate multi-page reports in a `reports` directory in your workspace.

Module functions
----------------

### Report

-   [create_report_context](create_report_context.m) - Create report context structure
-   [create_document](create_document.m) - Create a document handle
-   [report_challenge](report_challenge.m) - Generate an official challenge report
-   [report_article](report_article.m) - Generate an article friendly report
-   [report_ranking](report_ranking.m) - Generate a report based on A-R ranking
-   [report_submission](report_submission.m) - Basic performance scores for given trackers
-   [report_ranking_spotlight](report_ranking_spotlight.m) - Generate a spotlight report based on A-R ranking
-   [report_failures](report_failures.m) - Generate a statistic overview of occurences of failures
-   [report_difficulty](report_difficulty.m) - Generate a difficulty report for labels or sequences
-   [report_expected_overlap](report_expected_overlap.m) - Generate a report based on expected overlap
-   [report_sequences_preview](report_sequences_preview.m) - Create an overview document for the given sequences
-   [report_implementation](report_implementation.m) - Generate an overview of tracker implementations

### Resources and graphs

-   [generate_plot](generate_plot.m) - Generate an blank plot
-   [generate_ar_plot](generate_ar_plot.m) - Generate an A-R plot
-   [generate_ranking_plot](generate_ranking_plot.m) - Generate an A-R ranking plot
-   [generate_ordering_plot](generate_ordering_plot.m) - Generate a per-selector ordering plot
-   [generate_legend_plot](generate_legend_plot.m) - Generate a tracker legend plot
-   [generate_sequence_strip](generate_sequence_strip.m) - Generate an preview of a sequence as a strip of frames
-   [generate_timeline](generate_timeline.m) - Generate a timeline plot with intervals
-   [generate_sequence_preview](generate_sequence_preview.m) - Generates a sequence preview image

### Utilities

-   [report_cache](report_cache.m) - Cache proxy for report generation
-   [create_table_cell](create_table_cell.m) - Create a complex table cell structure
-   [highlight_best_rows](highlight_best_rows.m) - Adds highlight to the best three cells in a given
-   [tight_subplots](tight_subplots.m) - Initializes a grid of axes
-   [matrix2html](matrix2html.m) - Generates a HTML table for a given matrix
