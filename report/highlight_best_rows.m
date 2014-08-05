function tabledata = highlight_best_rows(tabledata, columns, varargin)

if size(tabledata, 2) ~= numel(columns)
    error('Number of columns does not match the sorting instructuions.');
end;

for i = 1:numel(columns)
    
    switch columns{i}
        case 'descending'
			values = cell2mat(tabledata(:, i));
			usable = find(~isnan(values));
            [~, indices] = sort(values(usable), 'descend');
            indices = usable(indices);
            
            tabledata{indices(1), i} = struct('text', tabledata{indices(1), i}, 'class', 'first');
            tabledata{indices(2), i} = struct('text', tabledata{indices(2), i}, 'class', 'second');
            tabledata{indices(3), i} = struct('text', tabledata{indices(3), i}, 'class', 'third');
            
        case 'ascending'
			values = cell2mat(tabledata(:, i));
			usable = find(~isnan(values));
            [~, indices] = sort(values(usable), 'ascend');
            indices = usable(indices);

            tabledata{indices(1), i} = struct('text', tabledata{indices(1), i}, 'class', 'first');
            tabledata{indices(2), i} = struct('text', tabledata{indices(2), i}, 'class', 'second');
            tabledata{indices(3), i} = struct('text', tabledata{indices(3), i}, 'class', 'third');
    end;
end;
