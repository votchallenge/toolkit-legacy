function [patch] = cut_patch(image, region)
% cut_patch extract smaller patch defined by region from an image
%
% Input:
% - image (matrix): n-dimensional WxH image
% - region (vector): axis-align bounding box defined as [top_left_x top_left_y width height]
%
% Output: (computed attributes are store in local file system)
% - patch (matrix): n-dimensional widthxheight image region

region = round(region);

x1 = max(1, region(1)+1);
y1 = max(1, region(2)+1);
x2 = min(size(image, 2), region(1)+region(3)+1);
y2 = min(size(image, 1), region(2)+region(4)+1);

if (size(image, 3) > 1)
    patch = image(y1:y2, x1:x2, :);    
else
    patch = image(y1:y2, x1:x2);
end;