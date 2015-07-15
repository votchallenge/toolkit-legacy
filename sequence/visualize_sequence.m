function visualize_sequence(sequence, varargin)
% visualize_sequence Interactive sequence visualization
%
% The function intereactivelly visualizes the given sequence and a set of results.
%
% Input:
% - sequence (structure): A valid sequence structure.
% - varargin (cell): An array of trajectories that are visualized together with
%   ground-truth data.
%

print_text('Press arrow keys or S,D,F,G to navigate the sequence, Q to quit.');

fh = figure;

if ~isempty(sequence.labels.names)

    names = sequence.labels.names;
    labels = sequence.labels.data;
    labelsplit = mat2cell(labels, size(labels, 1), ones(1, size(labels, 2)));

    for j = 2:nargin
        if ~iscell(varargin{j-1})
            continue;
        end;
        trajectory = varargin{j-1};
        labelsplit{end+1} = cellfun(@(x) numel(x) == 1, trajectory, 'UniformOutput', true);
        names{end+1} = sprintf('Trajectory %d', j-1);
    end;

    starts = cellfun(@(x) find(diff([0; x; 0]) > 0), labelsplit, 'UniformOutput', 0);
    ends = cellfun(@(x) find(diff([0; x; 0]) < 0), labelsplit, 'UniformOutput', 0);

    subplot(2,1,2);
    hold on;
    generate_timeline(names, starts, ends);
    set(gca,'xlim',[0 sequence.length]);
    slider = line([1 1], [0 numel(names)+1], 'LineWidth', 3, 'Color', [0 0 0 ]);
    hold off;

end;

i = 1;
while 1
    image_path = get_image(sequence, i);
    image = imread(image_path);
    hf = sfigure(fh);
    if ~isempty(sequence.labels.names)
        subplot(2,1,1, 'replace');
    end;
	set(hf, 'Name', sprintf('%s (%d / %d)', sequence.name, i, sequence.length), 'NumberTitle', 'off');
    imshow(image);
    hold on;
    draw_region(get_region(sequence, i), [1 0 0], 2);
    for j = 2:nargin
        if ~iscell(varargin{j-1}) || i > numel(varargin{j-1})
            continue;
        end;
        trajectory = varargin{j-1};    
		if numel(trajectory{i}) == 1
			continue;
		end;
        draw_region(trajectory{i}, [0 1 0], 1);
    end;
    if ~isempty(sequence.labels.names)
        active = sequence.labels.names(sequence.labels.data(i, :));
        if ~isempty(active)
            text(10, 10, strrep(strjoin(active, ', '), '_', '\_'), 'Color', 'w', 'BackgroundColor', [0, 0, 0]);
        end;
    end;
    hold off;
    if ~isempty(sequence.labels.names)
        set(slider, 'XData', [i i]);
    end;
    drawnow;
    try
	%k = waitforbuttonpress;
	[x y c] = ginput(1);
    catch 
        break
    end
    %if (k == 1)
        %c = get(hf, 'currentcharacter');
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
            elseif c == 'q' || c == -1
                break;
            else
                disp(uint8(c));
            end
        catch e
            print_text('Error %s', e.message);
        end
        %set(hf, 'currentcharacter', '?');
    %end;

end;

close(fh);

