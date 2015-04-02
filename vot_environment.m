function [sequences, experiments] = vot_environment()

try 
    
    % Attempts to load variables from the workspace namespace to save 
    % some time
    sequences = evalin('base', 'sequences');
    experiments = evalin('base', 'experiments');
    
    % Are variables correts at a glance ...
    cached = iscell(sequences) && iscell(experiments);
    
catch 
    
    cached = false;
    
end

configuration_file = fullfile(pwd(), 'configuration.m');

if ~exist(configuration_file, 'file')
    error('Directory is probably not a VOT workspace. Please run vot_initialize first.');
end;

script_directory = fileparts(mfilename('fullpath'));
include_dirs = cellfun(@(x) fullfile(script_directory,x), {'', 'utilities', ...
    'analysis', 'tracker', 'sequence', 'measures', 'experiment' ,'report'}, 'UniformOutput', false); 
addpath(include_dirs{:});

% Some defaults
set_global_variable('toolkit_path', fileparts(mfilename('fullpath')));
set_global_variable('indent', 0);
set_global_variable('directory', pwd());
set_global_variable('debug', 0);
set_global_variable('cache', 1);
set_global_variable('pack', 1);
set_global_variable('bundle', []);
set_global_variable('cleanup', 1);
set_global_variable('report', 1);
set_global_variable('matlab_startup_model', [923.5042, -4.2525]);
set_global_variable('report_template', fullfile(get_global_variable('toolkit_path'), 'templates', 'report.html'));

print_text('Initializing VOT environment ...');

global_configuration = get_global_variable('select_configuration', 'configuration');

try
	environment_configuration = str2func(global_configuration);
    environment_configuration();
catch e
    if exist(global_configuration) ~= 2 %#ok<EXIST>
        print_debug('Global configuration file does not exist. Using defaults.', ...
            global_configuration);
    else
        error(e);
    end; 
end;

native_dir = fullfile(get_global_variable('toolkit_path'), 'mex');
mkpath(native_dir);
addpath(native_dir);

compile_all_native(native_dir);

if cached
    print_debug('Skipping loading experiments and sequences');
else
    
    experiment_stack = get_global_variable('stack', 'vot2013');

    if exist(['stack_', experiment_stack]) ~= 2 %#ok<EXIST>
        error('Experiment stack %s not available.', experiment_stack);
    end;

    stack_configuration = str2func(['stack_', experiment_stack]);

    experiments = stack_configuration();

    sequences_directory = fullfile(get_global_variable('directory'), 'sequences');

    print_text('Loading sequences ...');

    sequences = load_sequences(sequences_directory, ...
        'list', get_global_variable('sequences', 'list.txt'));

    if isempty(sequences)
        error('No sequences available. Stopping.');
    end;

end;

