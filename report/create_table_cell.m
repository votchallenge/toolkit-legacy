function [table_cell] = create_table_cell(text, varargin)
% create_table_cell Create a complex table cell structure
%
% An utility function that creates a structure that describes a complex 
% table cell with styling and span.
%
% Input:
% - text (string): Text in a cell.
% - varargin (cell): Key-value pairs of additional arguments.
%
% Output:
% - table_cell (struct): A cell descriptor.
%


if ~isstruct(text)
    table_cell = struct('text', text, varargin{:});
else
    table_cell = struct(varargin{:});
    table_cell = struct_merge(table_cell, text);
end;