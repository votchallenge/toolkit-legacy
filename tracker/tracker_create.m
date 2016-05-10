function [identifier] = tracker_create(varargin)
% tracker_create Generate a new tracker configuration file
%
% This function helps with creation of a new tracker configuration file.
%
% Input:
% - varargin[Identifier] (string): Identifier of the new tracker. Must be a valid tracker name.
% - varargin[Directory] (string): Directory where the configuration file will be created.
%

identifier = [];
directory = pwd();

for j=1:2:length(varargin)
    switch lower(varargin{j})
        case 'identifier', identifier = varargin{j+1};
        case 'directory', directory = varargin{j+1};
        otherwise, error(['unrecognized argument ' varargin{j}]);
    end
end

if isempty(identifier)
    identifier = input('Input an unique identifier for your tracker: ', 's');
end;

if ~valid_identifier(identifier)
    error('Not a valid tracker identifier!');
end;

variables = {'tracker', identifier};

interpreter_names = {'Matlab', 'Python', 'C/C++', 'None of the above'};
interpreter_ids = {'matlab', 'python', '', ''};

print_text('Is your tracker written in any of the following languages?');
print_indent(1);

for i = 1:length(interpreter_ids)
    print_text('%d - "%s"', i, interpreter_names{i});
end;

print_indent(-1);

selected_interpreter = int32(str2double(input('Selected option: ', 's')));

if isempty(selected_interpreter) || selected_interpreter < 1 || selected_interpreter > length(interpreter_ids)
    selected_interpreter = numel(interpreter_names);
end;

if ~isempty(interpreter_ids{selected_interpreter})
    template_name = sprintf('tracker_%s.tpl', interpreter_ids{selected_interpreter});
else
    template_name = 'tracker.tpl';
end;

generate_from_template(fullfile(directory, ['tracker_', identifier, '.m']), ...
    fullfile(fileparts(mfilename('fullpath')), 'templates', template_name), variables{:});

