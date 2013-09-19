function visualize_sequence(sequence, varargin)

print_text('Press arrow keys or S,D,F,G to navigate the sequence, Q to quit.');

fh = figure(1);
i = 1;
while 1
    image_path = get_image(sequence, i);
    image = imread(image_path);
    hf = sfigure(1);
	set(hf, 'Name', sprintf('%s (%d / %d)', sequence.name, i, sequence.length), 'NumberTitle', 'off');
    imshow(image);
    hold on;
    draw_region(get_region(sequence, i), [1 0 0], 2);
    for j = 2:nargin
        if size(varargin{j-1}, 2) ~= 4 || i > size(varargin{j-1}, 1)
            continue;
        end;
        trajectory = varargin{j-1};
		if any(isnan(trajectory(i, :)))
			continue;
		end;
        draw_region(trajectory(i, :), [0 1 0], 1);
    end;
    if ~isempty(sequence.labels.names)
        active = sequence.labels.names(sequence.labels.data(i, :));
        if ~isempty(active)
            text(10, 10, strjoin(active, ', '), 'Color', 'w', 'BackgroundColor', [0, 0, 0]);
        end;
    end;
    hold off;
    drawnow;
    try
	k = waitforbuttonpress;
    catch 
        break
    end
    if (k == 1)
        c = get(hf, 'CurrentCharacter');
        try
            if c == ' ' || c == 'f' || uint8(c) == 29
                i = i + 1;
                if i > sequence.length
                    i = sequence.length;
                end;
            elseif c == 'd' || uint8(c) == 28
                i = i - 1;
                if i < 1
                    i = 1;
                end;   
            elseif c == 'g' || uint8(c) == 30
                i = i + 10;
                if i > sequence.length
                    i = sequence.length;
                end;
            elseif c == 's' || uint8(c) == 31
                i = i - 10;
                if i < 1
                    i = 1;
                end;              
            elseif c == 'q'
                break;
            else
                disp(uint8(c));
            end
        catch e
            print_text('Error %s', e);
        end
        set(hf, 'CurrentCharacter', '?');
    end;

end;

close(fh);

