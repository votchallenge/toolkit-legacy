function [mean_val, var_val, frames] = attribute_deformation(sequence)
% attribute_deformation Computes the deformation attribute of the object in the given seqeunce
%
% Deformation is calculated by dividing the images into 8x8 grid of cells 
% and computing the sum of squared differences of averaged pixel intensity 
% over the cells in current and first frame.
%
% Input:
% - sequence (struct): An array of sequence structures.
%
% Output:
% - mean_val : mean value of the deformation of the object for the sequence
% - val_val  : variance of the deformation of the object for the sequence
% - frames   : the deformation of the object for each frame

numOfCells = 8;

frames = zeros(sequence.length, 1);

image = rgb2gray(imread(get_image(sequence, 1)));
patch = cut_patch(image, region_convert(get_region(sequence, 1), 'rectangle'););


bb = region_convert(get_region(sequence, 1), 'rectangle');
cellWidth = bb(3)/numOfCells;
cellHeight = bb(4)/numOfCells;
xPos = round([1 1+round(cellWidth):cellWidth:bb(3)-round(cellWidth)  bb(3)]);
yPos = round([1 1+round(cellHeight):cellHeight:bb(4)-round(cellHeight)  bb(4)]);

meanIntensity = mean(double(patch(:)) ./ 255);

blockIntensity = zeros(length(xPos), length(yPos));
for j = 1:length(xPos)-1
    for k = 1:length(yPos)-1
        p = patch(yPos(k):yPos(k+1), xPos(j):xPos(j+1));
        blockIntensity(j, k) = mean(double(p(:)) ./ 255) - meanIntensity;
    end
end

frames(1) = 0;

xPosRelative = xPos./bb(3);
yPosRelative = yPos./bb(4);

for i = 2:sequence.length
    image = rgb2gray(imread(get_image(sequence, i)));
    patch = cut_patch(image, region_convert(get_region(sequence, i), 'rectangle'));

    bb = region_convert(get_region(sequence, i), 'rectangle');
    xPos = ceil(xPosRelative.*bb(3));
    yPos = ceil(yPosRelative.*bb(4));

    if isnan(bb(1))
        frames(i) = NaN;
        continue;
    end

    meanIntensity = mean(double(patch(:)) ./ 255);
    bi = zeros(length(xPos), length(yPos));
    for j = 1:length(xPos)-1
        for k = 1:length(yPos)-1
            x1 = round(min(max(1, xPos(j)),size(patch, 2)));
            y1 = round(min(max(1, yPos(k)),size(patch, 1)));
            x2 = round(min(size(patch, 2), xPos(j+1)));
            y2 = round(min(size(patch, 1), yPos(k+1)));
            p = patch(y1:y2, x1:x2);
            bi(j, k) = (mean(double(p(:)) ./ 255) - meanIntensity - blockIntensity(j, k))^2;
        end
    end
    frames(i) = sum(sum(abs(bi)));
end;

framesID = find(~isnan(frames));
mean_val = mean(abs(frames(framesID(2:end))));
var_val = var(frames(framesID(2:end)));
