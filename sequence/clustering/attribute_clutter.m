function [mean_val, var_val, frames] = attribute_clutter(sequence)
% attribute_clutter Computes the amount of clutter attribute seqeunce
%
% Clutter is the average of per-frame distances between two histograms: 
% one extracted from within the ground truth bounding box and one from an enlarged 
% area (by factor 1.5) outside of the bounding box.
%
% Input:
% - sequence (struct): An array of sequence structures.
%
% Output:
% - mean_val : mean value of the clutter for the sequence
% - val_val  : variance of the clutter for the sequence
% - frames   : the clutter for each frame

frames = zeros(sequence.length, 1);

f = 1.5;
b = 8;

for i = 1:sequence.length
    
    image = round(rgb2hsv(imread(get_image(sequence, i))) .* 255);
    region = region_convert(get_region(sequence, i), 'rectangle');;
    patch = cut_patch(image, region);
        
    if isnan(region(1))
        frames(i) = NaN;
        continue;
    end

    center = [region(1:2) + region(3:4) / 2];
    region_size = round([region(3:4)*sqrt(2)]);

    %region2 = round([(region(1:2) - region(3:4) * (f - 1) / 2), (region(3:4) * f)]);
    region2 = round([center(:) - region_size(:)/2, region_size(:)]);
    x1 = round(max(1, region2(1)+1));
    y1 = round(max(1, region2(2)+1));
    x2 = round(min(size(image, 2), region2(1)+region2(3)+1));
    y2 = round(min(size(image, 1), region2(2)+region2(4)+1));
    
    mask = false(uint32(size(image, 1)), uint32(size(image, 2)));
    mask(y1:y2, x1:x2) = 1;

    x1 = round(max(1, region(1)+1));
    y1 = round(max(1, region(2)+1));
    x2 = round(min(size(image, 2), region(1)+region(3)+1));
    y2 = round(min(size(image, 1), region(2)+region(4)+1));
    mask(y1:y2, x1:x2) = 0;
    
    c1 = image(:, :, 1);
    c2 = image(:, :, 2);
    c3 = image(:, :, 3);

    P = [c1(mask), c2(mask), c3(mask)];
    bghist = normalise(ndhistc(P, linspace(0,256,b+1), linspace(0,256,b+1), linspace(0,256,b+1)));
    
    c1 = patch(:, :, 1);
    c2 = patch(:, :, 2);
    c3 = patch(:, :, 3);
    
    P = [c1(:), c2(:), c3(:)];
    fghist = normalise(ndhistc(P, linspace(0,256,b+1), linspace(0,256,b+1), linspace(0,256,b+1)));
    
    d = sqrt( 0.5*sum( (sqrt(fghist(:)) - sqrt(bghist(:))).^2 )  ) ;    %Hellinger distance
    
    frames(i) = d;
    
end;

mean_val = mean(frames(~isnan(frames)));
var_val = var(frames(~isnan(frames)));

