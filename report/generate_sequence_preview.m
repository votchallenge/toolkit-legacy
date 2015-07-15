function file = generate_sequence_preview(sequence, trajectories, file, varargin)
% generate_sequence_preview Generates a sequence preview image
%
% Generates a preview animation for the sequence as an animated GIF.
%
% Input:
% - sequence (structure): A valid sequence structure.
% - trajectories (cell): An array of additional trajectories to draw.
% - file (string): Path to the destination file.
% - varargin[Samples] (integer): Number of preview images.
% - varargin[Scale] (double): Scaling factor.
% - varargin[Width] (double): Reference width.
% - varargin[Height] (double): Reference height.
% - varargin[GroundtruthColor] (vector): Color for groundtruth region.
% - varargin[TrajectoryColor] (cell): Color for groundtruth region.
% - varargin[Palette] (matrix): A color palette matrix for GIF images.
% - varargin[Delay] (integer): Delay between frames for GIF animation.
% - varargin[Loops] (integer): Number of loops in case for GIF animation.
% - varargin[Static] (integer): Also export a static version of the first
%   frame.
%
% Output:
% - file (string): Path to the destination file.
%

loops = inf;
delay = 0;
static = false;
samples = 12;
palette = 256;
scale = 1;

groundtruth_color = [0, 1, 0];
trajectories_colors = repmat([1, 0, 0], length(trajectories), 1);

for i = 1:2:length(varargin)
    switch lower(varargin{i})   
        case 'samples'
            samples = varargin{i+1};
        case 'scale'
            scale = varargin{i+1};
        case 'width'
            scale = varargin{i+1} / sequence.width;
        case 'height'
            scale = varargin{i+1} / sequence.height;
        case 'groundtruthcolor'
            groundtruth_color = varargin{i+1};
        case 'trajectorycolor'
            trajectories_colors = varargin{i+1};
        case 'palette'
            palette = max(2, min(256, varargin{i+1})); 
        case 'delay'
            delay = max(0, min(655, varargin{i+1}));
        case 'loops'
            loops = max(0, varargin{i+1});
        case 'static'
            static = max(0, varargin{i+1});
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

if size(trajectories_colors, 1) < length(trajectories)
    trajectories_colors = repmat(trajectories_colors(1, :), length(trajectories), 1);
end;

indices = round(linspace(1, sequence.length, samples));

animation = zeros(ceil(sequence.height * scale), ceil(sequence.width * scale), numel(indices), 3);

for i = 1:length(indices)

    image = double(imread(get_image(sequence, indices(i)))) / 255;

    if size(image, 3) == 1
       image = repmat(image, 1, 1, 3); 
    end
    
    image = imresize(image, scale);

    image_red = image(:, :, 1);
    image_green = image(:, :, 2);
    image_blue = image(:, :, 3);
    
    for t = 1:length(trajectories)
    
        region = trajectories{t}(indices(i), :);
        
        if any(isnan(region))
            continue;
        end;
        
        region = region_convert(region, 'polygon') .* scale;
    
        rasterized = edge(poly2mask(region(1:2:end), region(2:2:end), size(image, 1), size(image, 2)), 'canny');
        
        image_red(rasterized) = trajectories_colors(t, 1);
        image_green(rasterized) = trajectories_colors(t, 2);
        image_blue(rasterized) = trajectories_colors(t, 3);

    end;

    if ~isempty(groundtruth_color)
    
        region = get_region(sequence, indices(i));

        region = region_convert(region, 'polygon') .* scale;

        rasterized = edge(poly2mask(region(1:2:end), region(2:2:end), size(image, 1), size(image, 2)), 'canny');

        image_red(rasterized) = groundtruth_color(1);
        image_green(rasterized) = groundtruth_color(2);
        image_blue(rasterized) = groundtruth_color(3);
    
    end;
    
    animation(:, :, i, :) = cat(3, image_red, image_green, image_blue);
        
end

strip = reshape(animation, size(animation, 1), size(animation, 2) * size(animation, 3), 3);

% Obtain a palette over entire sequence strip, not just first
% image.
[strip, map] = rgb2ind(strip, palette, 'nodither');

animation = reshape(strip, size(animation, 1), size(animation, 2), 1, size(animation, 3));

[directory, name, ext] = fileparts(file);


if static

    file = fullfile(directory, [name, '_animated.gif']);

    imwrite(uint8(animation), map, file, 'DelayTime', delay, 'LoopCount', loops);

    file_static = fullfile(directory, [name, '_static.gif']);

    imwrite(uint8(animation(:, :, 1)), map, file_static);
else

    file = fullfile(directory, [name, '.gif']);

    imwrite(uint8(animation), map, file, 'DelayTime', delay, 'LoopCount', loops);

end


