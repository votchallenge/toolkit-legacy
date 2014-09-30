function vot_experiments(tracker, sequences, experiments)

print_text('Packing results ...');

print_indent(1);

%TODO: we have to test if the results are complete!
resultfile = pack_results(tracker, sequences, experiments);

print_indent(-1);

print_text('Result pack stored to "%s"', resultfile);

print_text('Done.');
