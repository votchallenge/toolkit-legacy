function do_experiments()

script_directory = fileparts(mfilename('fullpath'));
include_dirs = cellfun(@(x) fullfile(script_directory,x), {'', 'utilities', ...
    'tracker', 'sequence', 'measures', 'experiment', 'tests'}, 'UniformOutput', false); 
addpath(include_dirs{:});

initialize_environment;

summary = cell(length(experiments), 1); %#ok<USENS>

if length(trackers) == 1 %#ok<USENS>
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

    name = experiments{e}.name;
    execution = experiments{e}.execution;
    converter = experiments{e}.converter;
        
    if exist(['execution_', execution]) ~= 2
        print_debug('Warning: execution function %s not found. Skipping.', execution);
        continue;
    end;

    execution_function = str2func(['execution_', execution]);

    print_text('Running Experiment "%s" ...', name);

    print_indent(1);

    experiment_directory = fullfile(tracker.directory, experiments{e}.name);

    arguments = {};
    if isfield(experiments{e}, 'parameters')
        arguments = struct2opt(experiments{e}.parameters);
    end;
    
    summary{e} = execution_function(tracker, convert_sequences(sequences, converter), experiment_directory, arguments{:});

    print_indent(-1);

end;

if get_global_variable('report', 0)

    print_text('Generating report ...');
    
    print_indent(1);
    
    reportfile = write_report(sprintf('%s_%s', datestr(now, 30), ...
        tracker.identifier), tracker, sequences, experiments, summary);

    print_indent(-1);
    
    print_text('Report document written to "%s"', reportfile);
    
end;

if get_global_variable('pack', 0)

    print_text('Packing results ...');

    print_indent(1);

    resultfile = pack_results(tracker, sequences, experiments);

    print_indent(-1);

    print_text('Result pack stored to "%s"', resultfile);

else

    print_debug('Omitting result packaging.');

end;

print_text('Done.');
