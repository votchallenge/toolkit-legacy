function vot_initialize()
% Initialize a new VOT workspace

script_directory = fileparts(mfilename('fullpath'));
include_dirs = cellfun(@(x) fullfile(script_directory,x), ...
    {'utilities', 'tracker'}, 'UniformOutput', false); 
addpath(include_dirs{:});

initialize_defaults;

directory = pwd();

% Check if the directory is already a valid VOT workspace ...

configuration_file = fullfile(directory, 'configuration.m');

if exist(configuration_file, 'file')
    error('Directory is probably already a VOT workspace.');
end;

% Copy configuration templates ...

templates = fullfile(script_directory, 'templates');

version = vot_information();

tracker_identifier = input('Input an unique identifier for your tracker: ', 's');

if ~valid_identifier(tracker_identifier)
    error('Not a valid tracker identifier!');
end;

generate_from_template(fullfile(directory, 'configuration.m'), ...
    fullfile(templates, 'configuration.tpl'), 'version', num2str(version));

generate_from_template(fullfile(directory, 'run_experiments.m'), ...
    fullfile(templates, 'run_experiments.tpl'), 'tracker', tracker_identifier);

generate_from_template(fullfile(directory, 'run_test.m'), ...
    fullfile(templates, 'run_test.tpl'), 'tracker', tracker_identifier);

generate_from_template(fullfile(directory, 'run_browse.m'), ...
    fullfile(templates, 'run_browse.tpl'), 'tracker', tracker_identifier);

generate_from_template(fullfile(directory, 'run_analysis.m'), ...
    fullfile(templates, 'run_analysis.tpl'), 'tracker', tracker_identifier);

generate_from_template(fullfile(directory, ['tracker_', tracker_identifier, '.m']), ...
    fullfile(templates, 'tracker.tpl'), 'tracker', tracker_identifier);

generate_from_template(fullfile(directory, 'trackers.txt'), ...
    fullfile(templates, 'trackers.tpl'), 'tracker', tracker_identifier);

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