function handle = generate_ordering_plot(trackers, values, criteria, varargin)
% generate_ordering_plot Generate a per-selector ordering plot.
%
% Generate a per-selector ordering plot for either accuracy of robustness
% for a set of criteria.
%
% Input:
% - trackers (cell): A cell array of tracker structures.
% - values (matrix): Ranking or raw values for trackers.
% - criteria (cell): An array of criteria names.
% - varargin[Title] (string): A title of the plot.
% - varargin[Normalized] (boolean): A sensitivity parameter value.
% - varargin[Visible] (boolean): Is the figure visible on the display.
% - varargin[Width] (double): Figure width hint.
% - varargin[Height] (double): Figure height hint.
% - varargin[Flip] (boolean): Flip the horizontal axsis.
% - varargin[Type] (string): Name of the horizontal axis.
% - varargin[Scope] (double): Maximum number in horizontal axsis.
% - varargin[Handle] (handle): Plot on existing figure handle.
% - varargin[Legend] (boolean): Render plot legend.
%
% Output:
% - handle (handle): A figure handle.
%
    plot_title = [];
    normalized = 0;
    width = 9;
    height = max(3, numel(trackers) / 3);
    scope = [1, numel(trackers)];
    type = 'Rank';
    flip = 0;
    show_legend = 1;
    visible = false;
    handle = [];
    
    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'title'
                plot_title = varargin{i+1}; 
            case 'visible'
                visible = varargin{i+1}; 
            case 'normalized'
                normalized = varargin{i+1};      
            case 'width'
                width = varargin{i+1};
            case 'height'
                height = varargin{i+1};
            case 'scope'
                scope = varargin{i+1};
            case 'type'
                type = varargin{i+1};
            case 'flip'
                flip = varargin{i+1}; 
            case 'handle'
                handle = varargin{i+1};
            case 'legend'
                show_legend = varargin{i+1};
            otherwise 
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end 

    if isempty(handle)
        if ~visible
            handle = figure('Visible', 'off');
        else
            handle = figure();
        end
    else
        figure(handle);
    end;

    [~, I] = sort(values, 2, 'ascend');

    hold on; grid on; box on;

    if ~normalized
    
        for t = 1:length(trackers)

            x = values(:, t);

            plot(x, 1:length(criteria), [trackers{t}.style.symbol, '--'], ...
                'Color', trackers{t}.style.color, 'MarkerSize', 10,  'LineWidth', trackers{t}.style.width);

        end;

        if ~isempty(plot_title)
            title(plot_title,'interpreter','none');
        end;
    else
       
        for t = 1:length(trackers)

            x = mod(find(I' == t)-1, length(trackers))+1;

            plot(x, 1:length(criteria), [trackers{t}.style.symbol, '--'], ...
                'Color', trackers{t}.style.color, 'MarkerSize', 10,  'LineWidth', trackers{t}.style.width);

        end;

        if ~isempty(plot_title)
            title([plot_title, '(normalized)'],'interpreter', 'none');
        end;
    end;
    
    plot_labels = cellfun(@(tracker) tracker.label, trackers, 'UniformOutput', 0);
    if show_legend
        legend(plot_labels, 'Location', 'NorthEastOutside', 'interpreter', 'none'); 
    end;
    xlabel(type); 
    set(gca,'ytick', 1:numel(criteria),'yticklabel', criteria, 'YDir','Reverse', 'ylim', [0.9, numel(criteria)+0.1]);
    set(gca,'xtick', floor(scope(1)):ceil(scope(2)), 'xlim', scope + [-1, 1] * (diff(scope) / 100));

    if flip
        set(gca, 'xdir', 'reverse');
    end;
    set(gca, 'LineWidth', 2);
    hold off;
    
    set(handle, 'PaperUnits', 'inches', 'PaperSize', [width, height], 'PaperPosition', [0, 0, width, height]);

    
