function merged = struct_merge(from, to)
% struct_merge Merges a from structure to another in a recursive manner
%
% This function merges a from structure (array) to a to structure (array)
% in a recursive manner when values contain structures (arrays). At any
% level: 1) If two single structures are to be merged, the same fields in
% the to structure are overwritten by the fields in the from structure.
% Extract fields from the from structure are added to the to structure.
% 2) If one or both of the structures are arrays, they are concatenated
% in terms of their elements and merged in terms of their fields.
%
% Credit: Dongxi Zheng (2014)
%
% Input:
% - from (structure): A structure (or structure array) to be merged to another.
% - to (structure): A structure (or structure array) to be merged to.
%
% Output:
% - merged (structure): A merged structure (or structure array).

if isstruct(from) && isstruct(to)   
    from_count = numel(from);
    to_count = numel(to);
    % merge structure array with structure array
    if from_count > 1 && to_count > 1
        merged = sa2sa(from, to);
    % merge structure array to structure    
    elseif from_count > 1
        merged = sa2struct(from, to);
    % merge strucutre to structure array
    elseif to_count > 1
        merged = struct2sa(from, to);
    % merge structure to structure
    else
        merged = struct2struct(from, to);
    end
else
    merged = struct();
end

end

function to = struct2struct(from, to)
% Merge procedure for cases when none of the input structures is a
% structure array.

    % get the size of from structure's fields
    from_fields = fieldnames(from);
    n_fields = length(from_fields);
    
    % for each field in the from structure
    for i = 1:n_fields
        
        field = from_fields{i};
        from_v = from.(field);
        
        % If the value of the field in the from structure is a structure
        if isstruct(from_v)
            
            from_v_count = numel(from_v);
            
            % If the to structure contains the field
            if isfield(to, field)

                to_v = to.(field);
                to_v_count = numel(to_v);

                % If the field in the to structure is not empty and is also
                % a structure, recursively merge
                if (~isempty(to_v)) && isstruct(to_v)
                    
                    if from_v_count > 1 && to_v_count > 1
                        % merge structure array with structure array
                        to.(field) = sa2sa(from_v, to_v);
                    elseif from_v_count > 1
                        % merge structure array to structure
                        to.(field) = sa2struct(from_v, to_v);
                    elseif to_v_count > 1
                        % merge strucutre to structure array
                        to.(field) = struct2sa(from_v, to_v);
                    else
                        % merge structure to structure
                        to.(field) = struct2struct(from_v, to_v);
                    end
                    
                % If the field in the to structure is empty, simply copy
                % the value over from the from structure
                else
                    to.(field) = from_v;
                end

            % If the to structure doen't contain the field, copy this field
            % over from the from structure.
            else
                to.(field) = from_v;
            end
        
        % If the value of the field in the from structure is not a
        % structure
        else
            to.(field) = from_v;
        end
        
    end
end

function to = struct2sa(from, to)
% Merge procedure for cases when only the to structure is a structure array

    % get a reshaped to structure array
    to_size = size(to);
    to_count = numel(to);
    idx_append = to_count + prod(to_size(1:end-1));
    to = reshape(to, 1, to_count);
    
    % get the sizes of the from structure array and its fields
    from_fields = fieldnames(from);
    n_fields = length(from_fields);
    
    % for each field of the from structure, append the value to the end of
    % the to structure array
    for i = 1:n_fields
        field = from_fields{i};
        to(idx_append).(field) = from.(field);
    end
    
    % reshape the size of the to structure array back with only a change in
    % the last dimension
    to_size(end) = to_size(end) + 1;
    to = reshape(to, to_size);
end

function to = sa2struct(from, to)
% Merge procedure for cases when only the from structure is a structure
% array

    % simply switch their order and merge
    to = struct2sa(to, from);
end

function to = sa2sa(from, to)
% Merge procedure for cases when both the to structure and the from
% structure are structure arrays

    % reshape the to structure array to a one row array
    to_count = numel(to);
    to = reshape(to, 1, to_count);
    
    % get the sizes of the from structure array and its fields
    from_fields = fieldnames(from);
    n_fields = length(from_fields);
    from_count = numel(from);
    
    % for each field from the from structure array
    for i = 1:n_fields
        
        field = from_fields{i};
        
        % for each element in the from structure array
        for j = 1:from_count
            
            % append the value of the field to the to structure array at
            % the right position
            to(to_count+j).(field) = from(j).(field);
        end
    end
end
