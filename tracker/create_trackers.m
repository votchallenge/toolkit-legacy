function [trackers] = create_trackers(varargin)

identifiers = {};

for j = 1:nargin

    if exist(varargin{j}, 'file')

        ids = readfile(varargin{j}, ',');

        identifiers = [identifiers; ids(:)]; %#ok<AGROW>

    else
        
        % if the argument is not a file name, test if it is
        % a valid tracker identifier and use that
        if valid_identifier(varargin{j})
            identifiers = [identifiers; varargin(j)]; %#ok<AGROW>
        else
            continue;
        end;
        
    end;
    
end;

% remove the duplicate identifiers
identifiers = unique(identifiers);

trackers = cell(size(identifiers, 1), 1);

for i = 1:size(identifiers, 1)
    tracker_identifier = strtrim(identifiers{i});

    if isempty(tracker_identifier)
        break;
    end

    if ~valid_identifier(tracker_identifier)
        print_debug('Warning: %s is not a valid tracker identifier.', ...
            tracker_identifier);
    end;

    trackers{i} = create_tracker(tracker_identifier);

end;
