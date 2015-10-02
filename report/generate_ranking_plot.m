function handle = generate_ranking_plot(trackers, accuracy, robustness, varargin)
% generate_ar_plot Generate an A-R ranking plot
%
% The function generates an A-R ranking plot for a sequence of measurements.
%
% Input:
% - trackers (cell): A cell array of tracker structures.
% - accuracy (matrix): Accuracy ranks.
% - robustness (matrix): Robustness ranks.
% - varargin[Title] (string): A title of the plot.
% - varargin[Limit] (double): A manually set maximum rank.
% - varargin[Visible] (boolean): Is the figure visible on the display.
% - varargin[Width] (double): Figure width hint.
% - varargin[Height] (double): Figure height hint.
% - varargin[Handle] (handle): Plot on existing figure handle.
% - varargin[Legend] (boolean): Render plot legend.
%
% Output:
% - handle (handle): A figure handle.
%

    plot_title = [];
    visible = false; 
    plot_limit = numel(trackers);
    width = [];
    height = [];

    handle = [];

    show_legend = true;
    
    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'title'
                plot_title = varargin{i+1};
            case 'limit'
                plot_limit = varargin{i+1};
            case 'visible'
                visible = varargin{i+1};    
            case 'width'
                width = varargin{i+1};
            case 'height'
                height = varargin{i+1};
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

    if isempty(width)
        width = iff(show_legend, 6, 4);
    end

    if isempty(height)
        height = 4;
    end

    hold on; box on; grid on;
    title(plot_title, 'interpreter','none');

    available = true(length(trackers), 1);

    for t = 1:length(trackers)

        if isnan(accuracy(t))
            available(t) = 0;
            continue;
        end;

        plot(robustness(t), accuracy(t), trackers{t}.style.symbol, 'Color', ...
            trackers{t}.style.color, 'MarkerSize', 10, 'LineWidth', trackers{t}.style.width);

    end;
    plot_labels = cellfun(@(tracker) tracker.label, trackers, 'UniformOutput', 0);
    if show_legend
        legend(plot_labels(available), 'Location', 'NorthWestOutside', 'interpreter', 'none', 'FontSize', 9); 
    end;
    xlabel('Robustness rank'); set(gca, 'XDir', 'Reverse');
    ylabel('Accuracy rank'); set(gca, 'YDir', 'Reverse');
    xlim([0.9, plot_limit + 0.1]);
    ylim([0.9, plot_limit + 0.1]);
    
    set(handle, 'PaperUnits', 'inches', 'PaperSize', [width, height], 'PaperPosition', [0, 0, width, height]);
    
    hold off;
