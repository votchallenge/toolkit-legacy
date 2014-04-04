function writestruct(filename, s)

% Extract field data
fields = repmat(fieldnames(s), numel(s), 1);
values = struct2cell(s);

% Convert all numerical values to strings
idx = cellfun(@isnumeric, values); 
values(idx) = cellfun(@num2str, values(idx), 'UniformOutput', 0);

fid = fopen(filename, 'w');

cellfun(@(x, y) fprintf(fid, '%s=%s\n', x, y) , fields, values, 'UniformOutput', 0);

fclose(fid);