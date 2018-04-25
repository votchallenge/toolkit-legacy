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
% - varargin[Persist] (boolean, optional): Only applicable to 'sequential'
% execution mode, persist even if error was encountered for a specific
% sequence.
% - varargin[Log] (boolean, optional): Write a dedicated execution log to a
% file.
% - varargin[Pool] (integer, optional): Size of executor pool, only
% applicable to 'parallel' execution mode.
%

mode = 'sequential';
variables = [];
persist = false;
log = false;
pool = 1;
postprocess = [];

for j=1:2:length(varargin)
    switch lower(varargin{j})
        case 'mode', mode = varargin{j+1};
        case 'variables', variables = varargin{j+1};
        case 'persist', persist = varargin{j+1};
        case 'pool', pool = varargin{j+1};
        case 'log', log = varargin{j+1};
        otherwise, error(['unrecognized argument ', varargin{j}]);
    end
end

if isstruct(variables)
    print_debug('Setting additional global variables');
    set_global_variable(variables);
end

switch lower(mode)
    case 'sequential'
        if log
            if islogical(log)
                mkpath(fullfile(get_global_variable('directory'), 'logs'));
                log = fullfile(get_global_variable('directory'), 'logs', sprintf('%s.log', datestr(now, 30)));
            end;
            diary(log);
            cleanup = onCleanup(@() diary('off') );
        end
        iterator = @execute_iterator;
        context = struct('persist', persist, 'errors', 0);
        postprocess = @execute_join;
    case 'parallel'
        if is_octave()
            error('Parallel execution not available in Octave.');
        end;
        if isempty(gcp('nocreate'))
            parpool(pool);
        end
        iterator = @parallel_iterator;
        context.logdir = [];
        if log
            if islogical(log)
                log = fullfile(get_global_variable('directory'), 'logs', datestr(now, 30));
            end;
            mkpath(log);
            context.logdir = log;
        end
        postprocess = @parallel_join;
    case 'makefile'
        if ~isunix
            error('Exporting to Makefile only supported on Unix-like systems.');
        end;
        iterator = @makefile_iterator;
        total = numel(trackers) * numel(sequences) * numel(experiments);
        context = struct('makefilename', 'Makefile', 'total', total, 'logdir', []);
        if log
            if islogical(log)
                log = fullfile(get_global_variable('directory'), 'logs', datestr(now, 30));
            end;
            mkpath(log);
            context.logdir = log;
        end
    otherwise, error(['unrecognized mode ', mode]);
end

context = iterate(experiments, trackers, sequences, 'iterator', iterator, 'context', context);

if ~isempty(postprocess)
    postprocess(context); %#ok<NOEFF>
end

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
        try

            tracker_evaluate(event.tracker, event.sequence, event.experiment);

        catch e
			context.errors = context.errors + 1;
            if context.persist
            	disp(getReport(e));
            else
                rethrow(e);
            end

        end;

    end;

end

function execute_join(context)

if (context.errors == 0)
    print_text('Done.');
else
    print_text('Errors were encoutnered. Experiments not done.');
end;

end

function context = parallel_iterator(event, context)

switch (event.type)
    case 'sequence_enter'
        if isempty(context.logdir)
            log = false;
        else
            log = fullfile(context.logdir, sprintf('%s-%s-%s.log', event.tracker.identifier, event.experiment.name, event.sequence.name));
            context.logs{event.tracker_index, event.experiment_index, event.sequence_index} = log;
        end;
        context.tasks(event.tracker_index, event.experiment_index, event.sequence_index) = ...
            parfeval(@workspace_evaluate, 0, event.tracker, event.sequence, ...
            event.experiment, 'Variables', get_global_variable(), 'Log', log);
end;

end

function parallel_join(context)

while true
    try
        fetchNext(context.tasks(:));
    catch
    end;

    completed = [context.tasks.Read];
    if all(completed)
        break;
    else
        print_text('Waiting ... (%d/%d)', sum(completed), numel(completed));
    end;
end

errors = cellfun(@(t) isfield(t, 'ErrorIdentifier'), num2cell(context.tasks), 'UniformOutput', true);

if ~any(errors(:))
    print_text('Done.');
else
    print_text('Errors were encoutnered. Experiments not done.');
end;
end

function context = makefile_iterator(event, context)

switch (event.type)
    case 'enter'
        
        context.file = fopen(context.makefilename, 'w');
        context.jobdir = fullfile(get_global_variable('directory'), ...
            'cache', 'makejobs');
        context.current = 0;
        context.list = {};
        mkpath(context.jobdir);
        
        fprintf(context.file, 'JOBDIR="%s"\n', context.jobdir);
        if ~isempty(context.logdir)
            fprintf(context.file, 'LOGDIR="%s"\n', context.logdir);
        end;
        fprintf(context.file, 'WORKSPACE="%s"\n', fullfile(get_global_variable('directory')));
        fprintf(context.file, 'TOOLKIT="%s"\n', fullfile(get_global_variable('toolkit_path')));
        
        fprintf(context.file, '.DEFAULT_GOAL := all\n\n');
        
    case 'exit'
        
        fprintf(context.file, 'all: ');
        fprintf(context.file, strjoin(context.list, ' '));
        fprintf(context.file, '\n\t@echo "[100%%] Done."\n');
        
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
        
        tracker = event.tracker;
        sequence = event.sequence;
        experiment = event.experiment;
        globals = get_global_variable(); %#ok<NASGU>
        
        job_file = fullfile(context.jobdir, sprintf('%s_%s_%s.mat', ...
            tracker.identifier, experiment.name, sequence.name));
        
        job_path = fullfile('${JOBDIR}', sprintf('%s_%s_%s.mat', ...
            tracker.identifier, experiment.name, sequence.name));
        
        save(job_file, 'tracker', 'sequence', 'experiment', 'globals');
        
        fprintf(context.file, 'job_%s_%s_%s:\n', tracker.identifier, ...
            experiment.name, sequence.name);
        
        context.list{end+1} = sprintf( 'job_%s_%s_%s', tracker.identifier, ...
            experiment.name, sequence.name);
        
        script = sprintf('addpath(''${TOOLKIT}''); toolkit_path; load(''%s''); workspace_evaluate(tracker, sequence, experiment, ''Variables'', globals)', job_path);
        
        log = '';
        if ~isempty(context.logdir)
            log = sprintf('diary ''%s'';', fullfile('${LOGDIR}', ...
                sprintf('%s-%s-%s.log', event.tracker.identifier, event.experiment.name, event.sequence.name)));
        end
        
        if is_octave()
            octave_flags = {};
            if ispc()
                octave_executable = ['"', fullfile(matlabroot, 'bin', 'octave.exe'), '"'];
            else
                octave_executable = fullfile(matlabroot, 'bin', 'octave');
            end
            
            if compare_versions(version(), '4.0.0', '>=')
                octave_flags{end+1} = '--no-gui';
            end
            octave_script = sprintf('try; %s; catch ex; disp(ex.message); for i = 1:size(ex.stack) disp(''filename''); disp(ex.stack(i).file); disp(''line''); disp(ex.stack(i).line); endfor; end; quit;', script);
            command = sprintf('%s %s --eval "%s%s"', octave_executable, strjoin(octave_flags, ' '), log, octave_script);
        else
            if ispc()
                matlab_executable = ['"', fullfile(matlabroot, 'bin', 'matlab.exe'), '"'];
                matlab_flags = {'-nodesktop', '-nosplash', '-wait', '-minimize'};
            else
                matlab_executable = fullfile(matlabroot, 'bin', 'matlab');
                matlab_flags = {'-nodesktop', '-nosplash'};
            end
            
            matlab_script = sprintf('try; %s; catch ex; disp(getReport(ex)); end; quit;', script);
            command = sprintf('%s %s -r "%s%s"', matlab_executable, strjoin(matlab_flags, ' '), log, matlab_script);
            
        end
        
        fprintf(context.file, '\t@echo "[%*d%%] %s %s %s"\n', 3, round((context.current * 100) / context.total), ...
            tracker.identifier, experiment.name, sequence.name);
        fprintf(context.file, '\t@%s > /dev/null\n\n', command);
        
        context.current = context.current + 1;
        
end;

end
