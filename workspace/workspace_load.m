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
directory = pwd();

args = varargin;
for j=1:2:length(args)
    switch lower(varargin{j})
        case 'directory', directory = args{j+1};
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

configuration_file = fullfile(directory, 'configuration.m');

if ~exist(configuration_file, 'file')
    error('Directory is probably not a VOT workspace. Please run workspace_create first.');
end;

% Some defaults
set_global_variable('toolkit_path', fileparts(fileparts(mfilename('fullpath'))));
set_global_variable('indent', 0);
set_global_variable('directory', directory);
set_global_variable('debug', 0);
set_global_variable('cache', 1);
set_global_variable('bundle', []);
set_global_variable('cleanup', 1);
set_global_variable('native_url', 'http://box.vicos.si/vot/toolkit/');
set_global_variable('trax_url', 'https://github.com/votchallenge/trax/archive/master.zip');
set_global_variable('trax_mex', []);
set_global_variable('trax_client', []);
set_global_variable('trax_timeout', 30);
set_global_variable('matlab_startup_model', [923.5042, -4.2525]);
set_global_variable('legacy_rasterization', false);

print_text('Initializing VOT workspace ...');

configuration_script = get_global_variable('select_configuration', 'configuration');

if ~strcmp(directory, pwd())
    addpath(directory);
end;

try
	environment_configuration = str2func(configuration_script);
    environment_configuration();
catch e
    if exist(configuration_script) ~= 2 %#ok<EXIST>
        print_debug('Global configuration file does not exist. Using defaults.', ...
            configuration_script);
    else
        error(e);
    end; 
end;

native_dir = fullfile(get_global_variable('toolkit_path'), 'native');
mkpath(native_dir);
rmpath(native_dir); rehash; % Try to avoid locked files on Windows
initialize_native(native_dir);
addpath(native_dir);

if cached
    print_debug('Skipping loading experiments and sequences');
else
    
    experiment_stack = get_global_variable('stack', 'vot2013');

    if exist(['stack_', experiment_stack]) ~= 2 %#ok<EXIST>
        error('Experiment stack %s not available.', experiment_stack);
    end;

    stack_configuration = str2func(['stack_', experiment_stack]);

    experiments = stack_configuration();

    sequences_directory = fullfile(get_global_variable('data_path'), experiment_stack);

    print_text('Loading sequences ...');

    sequences = load_sequences(sequences_directory, ...
        'list', get_global_variable('sequences', 'list.txt'));

    if isempty(sequences)
        error('No sequences available. Stopping.');
    end;

end;

