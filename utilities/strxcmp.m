function result = strxcmp(data, query, operation, varargin)
% strxcmp Advanced substring comparison
%
% Enables several substring comparisons, prefix and suffix matching
%
% Input:
% - data (string): The data string.
% - query (string): The query string.
% - operation (string): The comparision operation to perform.
%
% Output:
% - result (boolean): The result of the comparison.
%

if ~ischar(data)
    error('First argument must be a string');
end;

if ~ischar(query)
    error('Second argument must be a string');
end;

if ~ischar(operation)
    error('Operation argument must be a string');
end;

N = numel(data);
M = numel(query);

switch (lower(operation))
    case 'prefix'
        if N < M
            result = false;
        else;
            result = strncmp(data, query, M);
        end;
    case 'suffix'
        if N < M
            result = false;
        else;
            result = strcmp(data(end-M+1:end), query);
        end;
    otherwise
        error('Unknown comparison operation');
end;


