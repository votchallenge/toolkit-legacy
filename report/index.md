Reporting module
================

This module contains functions used in generation of reports and visualizations. Most reports rely on report context structure that provides a simple mechanism to generate multi-page reports in a `reports` directory in your workspace.

Module functions
----------------

### Document

-   [document_context](document_context.m) - Create report context structure
-   [document_create](document_create.m) - Create a document handle
-   [document_cache](document_cache.m) - Run a function or return a cached result

### Report

-   [report_ranking](report_ranking.m) - Generate a report based on A-R ranking
-   [report_expected_overlap](report_expected_overlap.m) - Generate a report based on expected overlap
-   [report_precision_recall](report_precision_recall.m) - Generate a report based on tracking precision and recall
-   [report_failures](report_failures.m) - Generate a statistic overview of occurences of failures
-   [report_difficulty](report_difficulty.m) - Generate a difficulty report for tags or sequences
-   [report_sequences_preview](report_sequences_preview.m) - Create an overview document for the given sequences
-   [report_implementation](report_implementation.m) - Generate an overview of tracker implementations

### Plots

-   [plot_blank](plot_blank.m) - Generate a blank plot
-   [plot_ar](plot_ar.m) - Generate an A-R plot
-   [plot_ranking](plot_ranking.m) - Generate an A-R ranking plot
-   [plot_ordering](plot_ordering.m) - Generate a per-selector ordering plot
-   [plot_legend](plot_legend.m) - Generate a tracker legend plot
-   [plot_sequence_strip](plot_sequence_strip.m) - Generate an preview of a sequence as a strip of frames
-   [plot_timeline](plot_timeline.m) - Generate a timeline plot with intervals
-   [plot_sequence_preview](plot_sequence_preview.m) - Generates a sequence preview image

### Utilities

-   [create_table_cell](create_table_cell.m) - Create a complex table cell structure
-   [highlight_best_rows](highlight_best_rows.m) - Adds highlight to the best three cells in a given
-   [matrix2html](matrix2html.m) - Generates a HTML table for a given matrix
