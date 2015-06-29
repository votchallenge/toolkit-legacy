function [sequences, experiments] = workspace_load(varargin)
% workspace_load Initializes the current workspace 
%
% This function initializes the current workspace by reading sequences and
% experiments as well as initializing global variables. It also checks if native
% resources have to be downloaded or compiled.
%
% To make loading faster when running the script multiple times, it checks if
% sequences and experiments variables exist in the workspace and if they are 
% cell arrays and just reuses them. No further check is performed so this may
% lead to problems when switching workspaces. Clear the workspace or use 'Force'
% argument to avoid issues with cached data.
%
% Input:
% - varargin[Force] (boolean): Force reloading the sequences and experiments.
%
% Output:
% - sequences (cell): Array of sequence structures.
% - experiments (cell): Array of experiment structures.
%

force = false;

args = varargin;
for j=1:2:length(args)
    switch lower(varargin{j})
        case 'force', force = args{j+1};         
        otherwise, error(['unrecognized argument ' args{j}]);
    end
end

if ~force

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

else

    cached = false;

end;

configuration_file = fullfile(pwd(), 'configuration.m');

if ~exist(configuration_file, 'file')
    error('Directory is probably not a VOT workspace. Please run workspace_create first.');
end;

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

