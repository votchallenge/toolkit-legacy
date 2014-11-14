function tabledata = highlight_best_rows(tabledata, columns, varargin)

if size(tabledata, 2) ~= numel(columns)
    error('Number of columns does not match the sorting instructuions.');
end;

labels = {'first', 'second', 'third'};

for i = 1:numel(columns)

    values = cell2mat(tabledata(:, i));
    usable = find(~isnan(values));

    switch columns{i}
        case 'descending'

            levels = sort(unique(values(usable)), 'descend');

        case 'ascending'
            levels = sort(unique(values(usable)), 'ascend');

        otherwise
            levels = [];
    end;
    
    if isempty(levels)
        continue;
    end;
    
    for j = 1:min(numel(labels), numel(levels))
        tabledata(values == levels(j), i) = cellfun(...
            @(x) struct('text', x, 'class', labels{j}), tabledata(values == levels(j), i), 'UniformOutput', false);
        
    end
end;
