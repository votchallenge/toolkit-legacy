function sequence_visualize(sequence, varargin)
% sequence_visualize Interactive sequence visualization
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

run = true;
i = 1;

  function getposition(src, ~)
      xyz = get(src, 'CurrentPoint');
      i = min(max(round(xyz(1,1)), 1), sequence.length);
  end

  function getkey(src, ~)
      c = get(src, 'CurrentKey');
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
              run = false;
          else
              disp(uint8(c));
          end
  end

if ~isempty(sequence.tags.names)

    names = sequence.tags.names;
    tags = sequence.tags.data;
    tagsplit = mat2cell(tags, size(tags, 1), ones(1, size(tags, 2)));

    for j = 2:nargin
        if ~iscell(varargin{j-1})
            continue;
        end;
        trajectory = varargin{j-1};
        tagsplit{end+1} = cellfun(@(x) numel(x) == 1, trajectory, 'UniformOutput', true);
        names{end+1} = sprintf('Trajectory %d', j-1);
    end;

    starts = cellfun(@(x) find(diff([0; x; 0]) > 0), tagsplit, 'UniformOutput', 0);
    ends = cellfun(@(x) find(diff([0; x; 0]) < 0), tagsplit, 'UniformOutput', 0);


    subplot(2,1,2);
    hold on;
    plot_timeline(names, starts, ends);
    set(gca, 'xlim',[0 sequence.length]);
    set(gca, 'ButtonDownFcn', @getposition);
    set(gcf, 'KeyPressFcn', @getkey);

    slider = line([1 1], [0 numel(names)+1], 'LineWidth', 3, 'Color', [0 0 0 ]);
    hold off;

end;

while run
    image_path = sequence_get_image(sequence, i);
    image = imread(image_path);
    hf = sfigure(fh);
    if ~isempty(sequence.tags.names)
        subplot(2,1,1, 'replace');
    end;
	set(hf, 'Name', sprintf('%s (%d / %d)', sequence.name, i, sequence.length), 'NumberTitle', 'off');
    imshow(image);
    hold on;
    region_draw(sequence_get_region(sequence, i), [1 0 0], 2);
    for j = 2:nargin
        if ~iscell(varargin{j-1}) || i > numel(varargin{j-1})
            continue;
        end;
        trajectory = varargin{j-1};
		if numel(trajectory{i}) == 1
			continue;
		end;
        region_draw(trajectory{i}, [0 1 0], 1);
    end;
    if ~isempty(sequence.tags.names)
        active = sequence.tags.names(sequence.tags.data(i, :));
        if ~isempty(active)
            text(10, 10, strrep(strjoin(active, ', '), '_', '\_'), 'Color', 'w', 'BackgroundColor', [0, 0, 0]);
        end;
    end;
    hold off;
    if ~isempty(sequence.tags.names)
        set(slider, 'XData', [i i]);
    end;
    waitforbuttonpress;
%     try
%         [x, ~, c] = ginput(1);
%     catch
%         break
%     end


end;

close(fh);



end



