function workspace_evaluate(trackers, sequences, experiments, varargin)
% workspace_evaluate Perform evaluation of a set of trackers
%
% Perform or prepare evaluation of a set of trackers on a set of sequences for
% a set of experiments.
%
% Input:
% - trackers (cell or structure): Array of tracker structures.
% - sequences (cell or structure): Array of sequence structures.
% - experiments (cell or structure): Array of experiment structures.
% - varargin[Mode] (string, optional): Evaluation mode, at the moment only 'execute' mode is supported.
% - varargin[Variables] (struct, optional): Additional global variables to
% be merged with (override) the existing ones.
%

mode = 'execute';
variables = [];

for j=1:2:length(varargin)
    switch lower(varargin{j})
        case 'mode', mode = varargin{j+1};
        case 'variables', variables = varargin{j+1};
        otherwise, error(['unrecognized argument ' varargin{j}]);
    end
end

if isstruct(variables)
    print_debug('Setting additional global variables');
    set_global_variable(variables);
end

switch lower(mode)
    case 'execute'
        iterator = @execute_iterator;
        context = [];
    case 'makefile'
        if ~isunix
            error('Exporting to Makefile only supported on Unix-like systems.');
        end;
        iterator = @makefile_iterator;
        context = struct('makefilename', 'Makefile');
    otherwise, error(['unrecognized mode ' mode]);
end

iterate(experiments, trackers, sequences, 'iterator', iterator, 'context', context);

print_text('Done.');

end

function context = execute_iterator(event, context)

    switch (event.type)
        case 'experiment_enter'

            print_text('Experiment %s', event.experiment.name);

            print_indent(1);
        case 'experiment_exit'

            print_indent(-1);

        case 'tracker_enter'

            print_text('Tracker %s', event.tracker.identifier);

            print_indent(1);

        case 'tracker_exit'

            print_indent(-1);

        case 'sequence_enter'

            print_text('Sequence %s', event.sequence.name);

            tracker_evaluate(event.tracker, event.sequence, event.experiment);

    end;

end

function context = makefile_iterator(event, context)

    switch (event.type)
        case 'enter'

            context.file = fopen(context.makefilename, 'w');

        case 'exit'

            fclose(context.file);

        case 'experiment_enter'

            print_text('Experiment %s', event.experiment.name);

            print_indent(1);
        case 'experiment_exit'

            print_indent(-1);

        case 'tracker_enter'

            print_text('Tracker %s', event.tracker.identifier);

            print_indent(1);

        case 'tracker_exit'

            print_indent(-1);

        case 'sequence_enter'

            print_text('Sequence %s', event.sequence.name);

            execution_parameters = struct();
            if isfield(event.experiment, 'parameters')
                execution_parameters = event.experiment.parameters;
            end;

            sequence_directory = fullfile(event.tracker.directory, event.experiment.name, ...
                event.sequence.name);


            print_indent(1);

            output_directory = fullfile('$(RDR)', tracker.identifier, experiment.name, sequence.name);

            fprintf(out, 'run_%s_%s_%s: prepare_%s_%s_%s', tracker.identifier, ...
                    experiment.name, sequence.name, tracker.identifier, ...
                    experiment.name, sequence.name);
            cellfun(@(x) fprintf(out, ' %s', fullfile(output_directory, sprintf('%s_%03d.txt', sequence.name, x))), num2cell(1:repeat), 'UniformOutput', false);
            fprintf(out, '\n\t@A=() ; for N in $$(seq -f "%%03g" 1 %d) ; do T=`cat %s`; A+=($$(echo "scale=5; $$T / %d" | bc)) ; done; echo $$(IFS=,; echo "$${A[*]}") > %s', ...
                repeat, fullfile('$(CDR)', 'execution', tracker.identifier, experiment.name, sequence.name, '$$N', 'elapsed.txt'), ...
                sequence.length, fullfile(output_directory, sprintf('%s_time.txt', sequence.name)));

            fprintf(out, '\n\n');

            fprintf(out, 'prepare_%s_%s_%s:\n\t@mkdir -p "%s"\n\n', tracker.identifier, ...
                    experiment.name, sequence.name, output_directory);

            fprintf(out, 'clean_%s_%s_%s:', tracker.identifier, ...
                    experiment.name, sequence.name);
            cellfun(@(x) fprintf(out, ' clean_%s_%s_%s_%03d', tracker.identifier, ...
                    experiment.name, sequence.name, x), num2cell(1:repeat), 'UniformOutput', false);
            fprintf(out, '\n\t@rmdir "%s"\n\n', output_directory);

            for r = 1:repeat

                working_directory = fullfile(get_global_variable('directory'), ...
                    'cache', 'execution', tracker.identifier, experiment.name, ...
                    sequence.name, sprintf('%03d', r));
                working_path = fullfile('$(CDR)', 'execution', ...
                    tracker.identifier, experiment.name, ...
                    sequence.name, sprintf('%03d', r));

                context = struct('fake', true);
                options = struct2opt(experiment_arguments);
                mkpath(working_directory);
                command = tracker.run(tracker, sequence, context, 'directory', working_directory, options{:});

                trajectory_file = fullfile(output_directory, sprintf('%s_%03d.txt', sequence.name, r));
                timing_file = fullfile(working_path, 'elapsed.txt');

                current_task = current_task + 1;

                progress_indicator = sprintf('[%.0f%%]', 100 * current_task / total_tasks);

                fprintf(out, '%s: \n', trajectory_file);
                fprintf(out, '\t@echo "%s running %s, %s, %s, %03d"\n', progress_indicator, tracker.identifier, ...
                    experiment.name, sequence.name, r);
                fprintf(out, '\t@$(TIME) -o "%s" %s >/dev/null 2>&1\n', timing_file, command);
                fprintf(out, '\t@cp "%s" "%s" \n\n', fullfile(working_path, 'output.txt'), trajectory_file);

                fprintf(out, 'clean_%s_%s_%s_%03d: %s \n', tracker.identifier, ...
                    experiment.name, sequence.name, r, trajectory_file);
                fprintf(out, '\t@echo "%s removing %s ..."\n', progress_indicator, trajectory_file);
                fprintf(out, '\t@rm "%s" "%s" \n\n', fullfile(working_path, 'output.txt'), trajectory_file);

            end;


    end;

end
