function [trackers] = tracker_list(varargin)
% tracker_list Creates a set of tracker descriptor structures
%
% Create a cell array of new tracker structures from identifiers or file lists of identifiers.
%
% This functions checks each argument if it is a valid file and openes it as a text file of
% comma and new line separated tracker identifiers. If an argument is not a file then it is
% considered an identifier.
%
% Examples:
% 
%     trackers = tracker_list('trackers.txt', 'NCC'); % Load tracker identifiers from file trackers.txt and add a tracker NCC
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
        if file_exist(fullfile(pwd(), varargin{j}))

            ids = parsefile(fullfile(pwd(), varargin{j}), 'Delimiter', ',');

            identifiers = [identifiers; ids(:)]; %#ok<AGROW>

        else

            % if the argument is not a file name, but it is still a string ...
            if ischar(varargin{j})
                identifiers = [identifiers; varargin(j)]; %#ok<AGROW>
            end;

        end;
        
    end;

    % remove the duplicate identifiers
    if is_octave
        identifiers = unique(identifiers);
        print_debug('Warning: Tracker order is not preserved due to Octave limitations.')
    else
        identifiers = unique(identifiers, 'stable');
    end;

    trackers = cell(size(identifiers, 1), 1);

    for i = 1:size(identifiers, 1)
        tracker_identifier = strtrim(identifiers{i});

        if isempty(tracker_identifier)
            break;
        end

        trackers{i} = tracker_load(tracker_identifier);

    end;

    trackers = set_trackers_visual_identity(trackers);

end

% Matlab exist function is very flexible but also confuses script names for
% real files, therefore "ncc" will be considered a file if a file "ncc.m" exists
% in Matlab path. This can be problematic in our scenario. Therefore this function
% approaches the problem in a plain C way.
function status = file_exist(file_path)

    fd = fopen(file_path, 'r');

    status = fd > 0;

    if (fd > 0)
        fclose(fd);
    end;
end

