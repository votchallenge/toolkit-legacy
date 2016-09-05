function joined = strjoin(tokens, delimiter)
% strjoin Joins multiple strings
%
% Joins a cell array of strings in a single string with a given delimiter in between.
%
% Input:
% - tokens (cell): A cell array of strings.
% - delimiter (string): A delimiter string.
%
% Output:
% - joined (string): Joined string.
%

if nargin < 2
    delimiter = ' ';
end;

if ~iscell(tokens)
    joined = tokens;
    return;
end;

if isempty(tokens)
    joined = '';
    return;
end;

tokens = tokens(:)';

if numel(tokens) == 1
    joined = tokens{1};
    return;
end;

joined = cellfun(@(x) [delimiter, x], tokens(2:end), 'UniformOutput', false);
joined = [tokens{1} joined{:}];

