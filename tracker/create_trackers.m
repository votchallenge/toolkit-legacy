function [trackers] = create_trackers(varargin)
% create_trackers Creates a set of trackers
%
% Create a cell array of new tracker structures from identifiers or file lists of identifiers.
%
% This functions checks each argument if it is a valid file and openes it as a text file of
% comma and new line separated tracker identifiers. If an argument is not a file then it is
% considered an identifier.
%
% Examples:
% 
%     trackers = create_trackers('trackers.txt', 'NCC'); % Load tracker identifiers from file trackers.txt and add a tracker NCC
%
% Input:
% - varargin: A list of strings denoting either files containing tracker identifiers or valid identifiers. See `valid_identifier` for more details.
%
% Output:
% - trackers: A cell array of new tracker structures.

identifiers = {};

for j = 1:nargin
    
    %check if the first argument is a file, if so it is a 
    %text file containing a list of tracker names, ignore directories
    %(since the results folder migtht be on the path)
    if exist(varargin{j}, 'file') == 2

        ids = readfile(varargin{j}, 'Delimiter', ',');

        identifiers = [identifiers; ids(:)]; %#ok<AGROW>

    else

        % if the argument is not a file name, but it is still a string ...
        if ischar(varargin{j})
            identifiers = [identifiers; varargin(j)]; %#ok<AGROW>
        end;

    end;
    
end;

% remove the duplicate identifiers
identifiers = unique(identifiers, 'stable');

trackers = cell(size(identifiers, 1), 1);

for i = 1:size(identifiers, 1)
    tracker_identifier = strtrim(identifiers{i});

    if isempty(tracker_identifier)
        break;
    end

    trackers{i} = create_tracker(tracker_identifier);

end;

trackers = set_trackers_visual_identity(trackers);
