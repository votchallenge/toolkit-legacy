function workspace_submit(tracker, sequences, experiments, varargin)
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
% - varargin[Validate] (boolean): Should the results be validated for completeness.
% - varargin[Directory] (string): Directory where the archive is stored.
%
% Output:
% - resultfile (string): Path to the resulting archive.
%

    directory = fullfile(get_global_variable('directory'), 'archives');
    validate = true;

    for j=1:2:length(varargin)
        switch lower(varargin{j})
            case 'validate', validate = varargin{j+1};
            case 'directory', directory = varargin{j+1};         
            otherwise, error(['unrecognized argument ' varargin{j}]);
        end
    end

    print_text('Prepraring archive for tracker %s ...', tracker.identifier);    
    
    mkpath(directory);

    print_indent(1);

    context.completed = true;
    context.files = cell(0);

    context = iterate(experiments, tracker, sequences, 'iterator', @gather_iterator, 'context', context);

    if validate && ~context.completed
        print_text('Error: Results are not complete, submission not valid, aborting.');
        return;
    end;
    
    context.files{end+1} = write_manifest(tracker);

    tracker_performance_profile = fullfile(tracker.directory, 'performance.txt');
    writestruct(tracker_performance_profile, tracker.performance);
    context.files{end+1} = tracker_performance_profile;

    filename = sprintf('%s-%s.zip', tracker.identifier, datestr(now, 30));

    resultfile = fullfile(directory, filename);
    rootdir = fullfile(get_global_variable('directory'), 'results');

    files = cellfun(@(f) relativepath(f, rootdir), context.files, 'UniformOutput', false);

    print_indent(-1);
    
    print_text('Generating submission report ...');
    
    print_indent(1);
    
    report = report_submission(create_report_context(sprintf('submission_%s', tracker.identifier)), tracker, sequences, experiments);

    print_indent(-1);
    
    try    
        
        print_text('Generating results archive, compressing %d files ...', numel(files));

        zip(resultfile, files, rootdir);
        
        print_text('Result pack stored to "%s"', resultfile);

        print_text('');
        print_text('***************************************************************************');
        print_text('');
        print_text('The submission material is now ready.');
        print_text('You can find the archive with raw results in %s.', resultfile);
        print_text('The report with basic results can be found in %s.', report.target_file);
        print_text('You can copy the tables in the report to the supporting document of the submission.');
        print_text('Submit the archive and the document using the online form.');
        print_text('');
        print_text('***************************************************************************');
        print_text('');
        
    catch e

        print_text('Error: problem during creation of a result package: %s', e.message);

    end;
    
    print_text('Done.');

end

function context = gather_iterator(event, context)

    switch (event.type)
        case 'experiment_enter'
            
            print_text('Experiment %s', event.experiment.name);

            print_indent(1);       
        case 'experiment_exit'

            print_indent(-1);

        case 'tracker_enter'
            
        case 'tracker_exit'

        case 'sequence_enter'
            
            print_text('Sequence %s', event.sequence.name);

            execution_parameters = struct();
            if isfield(event.experiment, 'parameters')
                execution_parameters = event.experiment.parameters;
            end;
            
            sequence_directory = fullfile(event.tracker.directory, event.experiment.name, ...
                event.sequence.name);
            
            [files, metadata] = tracker_evaluate(event.tracker, event.sequence, sequence_directory, ...
                'type', event.experiment.type, 'parameters', execution_parameters, 'scan', true);

            context.files = [context.files, files];
            context.completed = context.completed && metadata.completed;
    end;

end

