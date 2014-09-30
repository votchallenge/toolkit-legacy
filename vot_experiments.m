function vot_experiments(tracker, sequences, experiments)

summary = cell(length(experiments), 1);

for e = 1:length(experiments)

    name = experiments{e}.name;
    execution = experiments{e}.execution;
    converter = experiments{e}.converter;
        
    if exist(['execution_', execution]) ~= 2 %#ok<EXIST>
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

print_text('Done.');
