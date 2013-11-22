function C = mergestruct(A, B)

M = [fieldnames(A)' fieldnames(B)'; struct2cell(A)' struct2cell(B)'];

[tmp, rows] = unique(M(1,:), 'last');
M=M(:, rows);

C=struct(M{:});