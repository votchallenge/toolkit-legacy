function vot_initialize()
% Initialize a new VOT workspace

script_directory = fileparts(mfilename('fullpath'));
include_dirs = cellfun(@(x) fullfile(script_directory,x), ...
    {'utilities', 'tracker'}, 'UniformOutput', false); 
addpath(include_dirs{:});

set_global_variable('toolkit_path', fileparts(mfilename('fullpath')));
set_global_variable('indent', 0);
set_global_variable('directory', pwd());

stacks = {};

files = dir(fullfile(script_directory, 'experiment'));

for i = 1:length(files)
    if ~files(i).isdir && strncmp(files(i).name, 'stack_', 6)
        stacks{end+1} = files(i).name(7:end-2);
    end;
end

directory = pwd();

% Check if the directory is already a valid VOT workspace ...

configuration_file = fullfile(directory, 'configuration.m');

if exist(configuration_file, 'file')
    error('Directory is probably already a VOT workspace.');
end;

% Copy configuration templates ...

templates = fullfile(script_directory, 'templates');

info = vot_information();

tracker_identifier = input('Input an unique identifier for your tracker: ', 's');

if ~valid_identifier(tracker_identifier)
    error('Not a valid tracker identifier!');
end;

print_text('Select one of the available experiment stacks:');

for i = 1:length(stacks)
    print_text(' %d - %s', i, stacks{i});
end;

option = input('Selection: ', 's');
option = int32(str2double(option));

if isempty(option) || option < 1 || option > length(stacks)
    error('Not a valid stack!');
end;

selected_stack = stacks{option};

variables = {'version', num2str(info.version), ...
    'tracker', tracker_identifier, 'stack', selected_stack};


generate_from_template(fullfile(directory, 'configuration.m'), ...
    fullfile(templates, 'configuration.tpl'), variables{:});

generate_from_template(fullfile(directory, 'run_experiments.m'), ...
    fullfile(templates, 'run_experiments.tpl'), variables{:});

generate_from_template(fullfile(directory, 'run_test.m'), ...
    fullfile(templates, 'run_test.tpl'), variables{:});

generate_from_template(fullfile(directory, 'run_pack.m'), ...
    fullfile(templates, 'run_pack.tpl'), variables{:});

generate_from_template(fullfile(directory, 'run_browse.m'), ...
    fullfile(templates, 'run_browse.tpl'), variables{:});

generate_from_template(fullfile(directory, 'run_analysis.m'), ...
    fullfile(templates, 'run_analysis.tpl'), variables{:});

generate_from_template(fullfile(directory, ['tracker_', tracker_identifier, '.m']), ...
    fullfile(templates, 'tracker.tpl'), variables{:});

% Print further instructions ...

print_text('');
print_text('***************************************************************************');
print_text('');
print_text('The VOT workspace has been configured');
print_text('Please edit the tracker_%s.m file to configure your tracker.', tracker_identifier);
print_text('Then run run_test.m script to make sure that the tracker is working.');
print_text('To run the experiments execute the run_experiments.m script.');
print_text('');
print_text('***************************************************************************');
print_text('');
