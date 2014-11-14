function [table_cell] = create_table_cell(text, varargin)

if ~isstruct(text)
    table_cell = struct('text', text, varargin{:});
else
    table_cell = struct(varargin{:});
    table_cell = struct_merge(table_cell, text);
end;