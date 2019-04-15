
tracker_label = 'Demo_Matlab';

tracker_command = generate_matlab_command('ncc', ...
    {'<path-to-toolkit-dir>\tracker\examples\matlab'}); % tracker source and vot.m are here

tracker_interpreter = 'matlab';

% tracker_linkpath = {}; % A cell array of custom library directories used by the tracker executable (optional)

