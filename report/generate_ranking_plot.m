function hf = generate_ranking_plot(trackers, accuracy, robustness, varargin)

    plot_title = [];
    visible = false; 
    plot_limit = numel(trackers);
    width = [];
    height = [];

    hf = [];

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
                hf = varargin{i+1};
            case 'legend'
                show_legend = varargin{i+1};                    
            otherwise 
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end 

    if isempty(hf)
        if ~visible
            hf = figure('Visible', 'off');
        else
            hf = figure();
        end
    else
        figure(hf);
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
    xlabel('Robustness rank'); set(gca,'XDir','Reverse');
    ylabel('Accuracy rank'); set(gca,'YDir','Reverse');
    xlim([1, plot_limit]); 
    ylim([1, plot_limit]);
    
    set(hf, 'PaperUnits', 'inches', 'PaperSize', [width, height], 'PaperPosition', [0, 0, width, height]);
    
    hold off;
