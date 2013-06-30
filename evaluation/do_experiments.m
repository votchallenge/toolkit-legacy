
script_directory = fileparts(mfilename('fullpath'));
include_dirs = cellfun(@(x) fullfile(script_directory,x), {'', 'utilities', 'tracker', 'sequence', 'measures', 'experiment'}, 'UniformOutput', false); 
if exist('strsplit') ~= 2
	remove_dirs = include_dirs;
else
	% if strsplit is available we can filter out missing paths to avoid warnings
	remove_dirs = include_dirs(ismember(include_dirs, strsplit(path, pathsep)));
end;
if ~isempty(remove_dirs) 
	rmpath(remove_dirs{:});
end;
addpath(include_dirs{:});

initialize_environment;

experiments = {'baseline', 'grayscale', 'region_noise'};

if exist('select_experiment', 'var')
	selected_experiments = unique(select_experiment(select_experiment > 0 && ...
        select_experiment <= length(experiments)));
else
	selected_experiments = 1:length(experiments);
end;

summary = cell(length(experiments), 1);

for e = selected_experiments

    if exist(['experiment_', experiments{e}]) ~= 2
        continue;
    end;

    experiment_function = str2func(['experiment_', experiments{e}]);

    print_text('Running Experiment "%s" ...', experiments{e});

    print_indent(1);

    experiment_directory = fullfile(tracker.directory, experiments{e});

    summary{e} = experiment_function(tracker, sequences, experiment_directory);

    scores = calculate_ar_score(tracker, sequences, experiment_directory);

    print_indent(-1);

end;

if track_properties.pack

    print_text('Packing results ...');

    print_indent(1);

    resultfile = pack_results(tracker, sequences, experiments);

    print_indent(-1);

    print_text('Result pack stored to "%s"', resultfile);

else

    print_debug('Omitting result packaging.');

end;

print_text('Done.');
