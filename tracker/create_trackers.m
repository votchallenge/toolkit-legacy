function [trackers] = create_trackers(varargin)

identifiers = {};

for j = 1:nargin

    if exist(varargin{j}, 'file')

        ids = readfile(varargin{j}, 'Delimiter', ',');

        identifiers = [identifiers; ids(:)]; %#ok<AGROW>

    else
        
        % if the argument is not a file name ...
        identifiers = [identifiers; varargin(j)]; %#ok<AGROW>

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
