function scores = execution_default(tracker, sequences, directory, varargin)

arguments.skip_labels = {};
arguments.skip_initialize = get_global_variable('skipping', 1);
arguments.fail_overlap = get_global_variable('fail', 0.0);
arguments.repetitions = get_global_variable('repeat', 1);

args = varargin;
for j=1:2:length(args)
    switch varargin{j}
        case 'skip_labels', arguments.skip_labels = args{j+1};
        case 'skip_initialize', arguments.skip_initialize = args{j+1};            
        case 'fail_overlap', arguments.fail_overlap = args{j+1};            
        otherwise, error(['unrecognized argument ' args{j}]);
    end
end

options = struct2opt(arguments);

for i = 1:length(sequences)
    print_text('Sequence "%s" (%d/%d)', sequences{i}.name, i, length(sequences));
    repeat_trial(tracker, sequences{i}, fullfile(directory, sequences{i}.name), options{:});
end;

scores = calculate_scores(tracker, sequences, directory);

print_text('Experiment complete.');

print_scores(sequences, scores);
