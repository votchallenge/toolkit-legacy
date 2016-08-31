function string = json_encode(object)
% json_encode Converts structure to a JSON string
%
% This function converts a structure or a cell array to a JSON string 
% representation. It supports encoding of structures, cell arrays
% strings and matrices. Both matrices and cell arrays are first 
% converted to single dimension lists as JSON does not support
% multiple dimensions.
%
% Input:
% - object (struct, cell): A Matlab structure
%
% Output:
% - string (string): An encoded JSON string
%
string = save_element(object);

end

function string = save_element(object)

if isstruct(object)
    string = save_struct(object);
elseif iscell(object)
    string = save_cell(object);
elseif ischar(object)
    string = save_string(object);
else
    string = save_matrix(object);
end

end

function string = save_struct(object)

fields = repmat(fieldnames(object), numel(object), 1);
values = struct2cell(object);

string = ['{', strjoin(cellfun(@(x, y) sprintf('"%s" : %s', x, save_element(y)), fields, values, 'UniformOutput', 0), ','), '}'];
end

function string = save_cell(object)

string = ['[', strjoin(cellfun(@(x) save_element(x), object(:), 'UniformOutput', 0), ','), ']'];
end

function string = save_string(object)

string = ['"', strrep(object, '"', '\"'), '"'];

end

function string = save_matrix(object)

if isempty(object)
    string = 'null';
elseif numel(object) == 1
    string = num2str(object);
else
    string = ['[', strjoin(cellfun(@(x) num2str(x), num2cell(object(:)', numel(object)), 'UniformOutput', 0), ','), ']'];
end;

end
