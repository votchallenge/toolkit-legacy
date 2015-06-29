function [new, mask] = patch_operation(matrix, patch, offset, operation)
% patch_operation Performs a point-wise operation with two unequal matrices
%
% Performs a point-wise operation (e.g. assignment, arithmetic) between two matrices
% that are not of the same size with a given offset. The result has the size of the 
% first matrix and the outlying elements are left intact.
%
% Input:
% - matrix (matrix): First operand matrix.
% - patch (matrix): Second operand matrix.
% - offset (vector): Two-element vector that defines the row and column offset of the second operand.
% - operation (char): A char that defines the type of the operation.
%     - '+': addition
%     - '-': subraction
%     - '*': multiplication
%     - '/': division
%     - '=': assignment
%
% Output:
% - new (matrix): Resulting matrix.
% - mask (matrix): Binary mask of the elements that were affected by the operation.
%


if nargin < 4
    operation = '=';
end;

[w1, h1, d2] = size(matrix); %#ok<*NASGU>
[w2, h2, d2] = size(patch);

offset = int16(offset);

xd1 = uint16(min([w1, max([offset(1), 1])]));
xd2 = uint16(min([w1, max([offset(1) + w2 - 1, 1])]));
yd1 = uint16(min([h1, max([offset(2), 1])]));
yd2 = uint16(min([h1, max([offset(2) + h2 - 1, 1])])); 

xs1 = uint16(min([w2, max([-offset(1) + 2, 1])]));
xs2 = uint16(min([w2, max([-offset(1) + w1 + 1, 1])]));
ys1 = uint16(min([h2, max([-offset(2) + 2, 1])]));
ys2 = uint16(min([h2, max([-offset(2) + h1 + 1, 1])])); 

if (xd1 > xd2 || yd1 > yd2)
    new = matrix;
    return;
end;

new = matrix;

switch (operation)
    case '-'
        new(xd1:xd2, yd1:yd2, :) = new(xd1:xd2, yd1:yd2, :) - patch(xs1:xs2, ys1:ys2, :);
    case '+'
        new(xd1:xd2, yd1:yd2, :) = new(xd1:xd2, yd1:yd2, :) + patch(xs1:xs2, ys1:ys2, :);
    case '*'
        new(xd1:xd2, yd1:yd2, :) = new(xd1:xd2, yd1:yd2, :) .* patch(xs1:xs2, ys1:ys2, :);
    case '/'
        new(xd1:xd2, yd1:yd2, :) = new(xd1:xd2, yd1:yd2, :) ./ patch(xs1:xs2, ys1:ys2, :);
    case '='
        new(xd1:xd2, yd1:yd2, :) = patch(xs1:xs2, ys1:ys2, :);
end;

if (nargout > 1)
    mask = zeros(w1, h1);
    mask(xd1:xd2, yd1:yd2) = 1;
end;

