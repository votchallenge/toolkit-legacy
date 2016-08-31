function tabledata = highlight_best_rows(tabledata, columns, varargin)
% highlight_best_rows Adds highlight to the best three cells in a given
% row.
%
% The function modifies the input matrix by converting it to cell array
% and augmenting the cells in individual columns with class labels for
% first three places acording to specified ordering. The resulting array
% can be then handed over to matrix2html function.
%
% Input:
% - tabledata (matrix): <description>
% - columns (cell): An array of strings that denote type of ordering for
% individual columns. 
%     - Decreasing: Highlight in decreasing order.
%     - Increasing: Highlight in increasing order.
%     - None: Do not highlight.
%
% Output:
% - tabledata (cell): Modified array.
%

if size(tabledata, 2) ~= numel(columns)
    error('Number of columns does not match the sorting instructuions.');
end;

labels = {'first', 'second', 'third'};

for i = 1:numel(columns)

    switch lower(columns{i})
        case {'descending', 'descend', 'high'}
            values = cell2mat(tabledata(:, i));
            usable = find(~isnan(values));
            levels = sort(unique(values(usable)), 'descend');

        case {'ascending', 'ascend', 'low'}
            values = cell2mat(tabledata(:, i));
            usable = find(~isnan(values));
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
