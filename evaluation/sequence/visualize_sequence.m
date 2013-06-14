function visualize_sequence(sequence, varargin)

for i = 1:sequence.length
    image_path = get_image(sequence, i);
    image = imread(image_path);
    figure(1);
    imshow(image);
    hold on;
    draw_region(get_region(sequence, i), [1 0 0], 2);
    for j = 2:nargin
        if size(varargin{j-1}, 2) ~= 4 || i > size(varargin{j-1}, 1)
            continue;
        end;
        trajectory = varargin{j-1};
        draw_region(trajectory(i, :), [0 1 0], 1);
    end;
    hold off;
	pause(0.2);
    drawnow;
end;



