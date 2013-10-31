function do_experiments()

% script_directory = fileparts(mfilename('fullpath'));
% include_dirs = cellfun(@(x) fullfile(script_directory,x), {'', 'utilities', ...
%     'tracker', 'sequence', 'measures', 'experiment', 'tests'}, 'UniformOutput', false); 
% if exist('strsplit') ~= 2
% 	remove_dirs = include_dirs;
% else
% 	% if strsplit is available we can filter out missing paths to avoid warnings
% 	remove_dirs = include_dirs(ismember(include_dirs, strsplit(path, pathsep)));
% end;
% if ~isempty(remove_dirs) 
% 	rmpath(remove_dirs{:});
% end;
% addpath(include_dirs{:});

initialize_environment;

summary = cell(length(experiments), 1);

if length(trackers) == 1
    selected_tracker = 1;
else

    print_text('Choose tracker:');
    print_indent(1);

    for i = 1:length(trackers)
        print_text('%d - "%s"', i, trackers{i}.identifier);
    end;

    print_text('e - Exit');
    print_indent(-1);

    option = input('Selected tracker: ', 's');

    if (option == 'q' || option == 'e')
        return;
    end;

    selected_tracker = int32(str2double(option));

    if isempty(selected_tracker) || selected_tracker < 1 || selected_tracker > length(trackers)
        return;
    end;

end;

tracker = trackers{selected_tracker};

for e = selected_experiments

    if exist(['experiment_', experiments{e}]) ~= 2
        print_debug('Warning: experiment %s not found. Skipping.', experiments{e});
        continue;
    end;

    experiment_function = str2func(['experiment_', experiments{e}]);

    print_text('Running Experiment "%s" ...', experiments{e});

    print_indent(1);

    experiment_directory = fullfile(tracker.directory, experiments{e});

    summary{e} = experiment_function(tracker, sequences, experiment_directory);

    print_indent(-1);

end;

if track_properties.report

    print_text('Generating report ...');
    
    print_indent(1);
    
    reportfile = write_report(sprintf('%s_%s', datestr(now, 30), ...
        tracker.identifier), tracker, sequences, experiments, summary);

    print_indent(-1);
    
    print_text('Report document written to "%s"', reportfile);
    
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
