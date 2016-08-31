function data = parsefile(filename, varargin)
% parsefile Parse a file to a cell array
%
% A general purpose function that parses a file into a cell array of
% elements based on a delimiter string and a parser function.
%
% Input:
% - filename (<type>): <description>
% - varargin[Delimiter] (string): An element delimiter string.
% - varargin[Parser] (function): A parser function that receives text data 
%   for an element and returns parsed content.
%
% Output:
% - data (cell): Resulting cell array.
%


parser = @default_cell_parser;

delimiter = ',';

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'delimiter'
            delimiter = varargin{i+1};
        case 'parser'
            parser = varargin{i+1};

        otherwise
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 


% Initialize the variable output argument
data = cell(0, 0);

fid = fopen(filename, 'r');

lineindex = 0;

while true
    % Get the current line
    line = fgetl(fid);
    
    % Stop if EOF
    if line == -1
        break;
    end
    
    lineindex = lineindex + 1;
    
    % Split the line string into components and parse numbers
    p = strfind(line, delimiter);
    if ~isempty(p)
        nt = numel(p) + 1;
        elements = cell(1, nt);
        sp = 1;
        dl = length(delimiter);
        for i = 1 : nt-1
            elements{i} = strtrim(line(sp:p(i)-1));
            sp = p(i) + dl;
        end
        elements{nt} = strtrim(line(sp:end));
    else
        elements = {line};
    end
    
    parsed = cellfun(parser, elements, 'UniformOutput', false);

    if (lineindex == 1)
        data = parsed;
    else
        data(lineindex, :) = parsed;
    end
    
end;

end

function [value] = default_cell_parser(text) 

    value = str2double(text);

    if isnan(value)
       value = text; 
    end
    
end

