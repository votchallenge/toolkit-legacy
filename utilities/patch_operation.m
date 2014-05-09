function [new, mask] = patch_operation(matrix, patch, offset, operation)

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
    case '<'
        new(xd1:xd2, yd1:yd2, :) = (new(xd1:xd2, yd1:yd2, :) - patch(xs1:xs2, ys1:ys2, :)) > 0;
end;

if (nargout > 1)
    mask = zeros(w1, h1);
    mask(xd1:xd2, yd1:yd2) = 1;
end;

