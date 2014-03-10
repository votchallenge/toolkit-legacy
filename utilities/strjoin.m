function joined = strjoin(tokens, delimiter)

if ~iscell(tokens)
    joined = tokens;
    return;
end;

if isempty(tokens)
    joined = [];
    return;
end;

if numel(tokens) == 1
    joined = tokens{1};
    return;
end;

joined = cellfun(@(x) [delimiter, x], tokens(2:end), 'UniformOutput', false);
joined = [tokens{1} joined{:}];

