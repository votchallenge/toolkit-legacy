function workspace_submit(tracker, sequences, experiments)
% workspace_submit Generates a valid result archive
%
% This function generates a valid result archive that can be submitted as a
% challenge entry. The archive includes raw results for a tracker and some
% metadata to help with the analysis and interpretation.
%
% Input:
% - tracker (structure): A valid tracker structure.
% - sequences (cell): Array of sequence structures.
% - experiments (cell): Array of experiment structures.
%

print_text('Packing results ...');

print_indent(1);

%TODO: we have to test if the results are complete!
resultfile = pack_results(tracker, sequences, experiments);

print_indent(-1);

print_text('Result pack stored to "%s"', resultfile);

print_text('Done.');
