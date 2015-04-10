function [hf] = generate_sequence_strip(sequence, trajectories, varargin)

visible = false;
trajectories_markers = {};
window = 120;
samples = 12;
scale = 1;
frame_numbers = false;

groundtruth_color = [0, 1, 0];
trajectories_colors = repmat([1, 0, 0], length(trajectories), 1);

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'visible'
            visible = varargin{i+1};    
        case 'window'
            window = varargin{i+1};
        case 'samples'
            samples = varargin{i+1};
        case 'scale'
            scale = varargin{i+1};
        case 'framenumbers'
            frame_numbers = varargin{i+1};            
        case 'groundtruthcolor'
            groundtruth_color = varargin{i+1};
        case 'trajectorycolor'
            trajectories_colors = varargin{i+1};
        case 'trajectorymarkers'
            trajectories_markers = varargin{i+1};            
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 


if numel(samples) > 1
    indices = samples(samples > 0 & samples <= sequence.length);
else
    indices = round(linspace(1, sequence.length, samples));
end;

if visible
    hf = figure();
else
    hf = figure('Visible', 'off');
end;

handles = tight_subplot(1, length(indices), 0, 0, 0);

for i = 1:length(indices)

	if isinf(window)

		offset = [0, 0];

		patch = imread(get_image(sequence, indices(i)));

	else

	    patch = zeros(window, window, 3);

		region = region_convert(get_region(sequence, indices(i)), 'rectangle');

		offset = region(1:2) + (region(3:4) - window) / 2;

		source = imread(get_image(sequence, indices(i)));

		patch = patch_operation(patch, source, -offset([2, 1]), '=');

	end;

    axes(handles(i)); %#ok<LAXES>
    
    if ~visible
        set(hf, 'Visible', 'off');
    end;

    axis tight;

    imshow(uint8(patch));

    hold on;
    
    for t = 1:length(trajectories)
    
        region = trajectories{t}{indices(i)};
        
        if numel(region) < 2;
            continue;
        end;

        region = region_offset(region, -offset);

        draw_region(region, trajectories_colors{t}, 2);
        
        if ~isempty(trajectories_markers)
            bounds = region_convert(region, 'rectangle');
            center = bounds(1:2) + bounds(3:4) / 2;

            plot(center(1), center(2), trajectories_markers{t}, 'MarkerSize', 7, 'LineWidth', 1.2, 'Color', trajectories_colors{t});

        end;
        
    end;

    if ~isempty(groundtruth_color)
    
        region = get_region(sequence, indices(i));

        region = region_offset(region, -offset);

        draw_region(region, groundtruth_color, 2);

    end;
    
    if frame_numbers
        text(10, 10, sprintf('%d', indices(i)), 'Color', 'w', 'BackgroundColor', [0, 0, 0]);
        
    end;
    
    hold off;
end

width = numel(indices);
height = 1;

set(hf, 'PaperUnits', 'inches', 'PaperSize', [width, height] * scale, 'PaperPosition', [0, 0, width, height] * scale);
