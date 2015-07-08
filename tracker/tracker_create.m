function [identifier] = tracker_create(varargin)
% tracker_create Generate a new tracker configuration file
%
% This function helps with creation of a new tracker configuration file.
%
% Input:
% - varargin[Identifier] (string): Identifier of the new tracker. Must be a valid tracker name.
% - varargin[Directory] (string): Directory where the configuration file will be created.
% - varargin[Matlab] (boolean): Is the tracker written in Matlab.
%

identifier = [];
directory = pwd();
matlab = false;

for j=1:2:length(varargin)
    switch lower(varargin{j})
        case 'identifier', identifier = varargin{j+1};
        case 'directory', directory = varargin{j+1};
        case 'matlab', matlab = varargin{j+1};
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

template_name = 'tracker.tpl';

matlab = strcmp('y', lower(input('Is the tracker written in Matlab? Y/N [N]: ', 's')));

if matlab
	template_name = 'tracker_matlab.tpl';	
end

generate_from_template(fullfile(directory, ['tracker_', identifier, '.m']), ...
    fullfile(fileparts(mfilename('fullpath')), 'templates', template_name), variables{:});

