function hf = generate_ar_plot(trackers, accuracy, robustness, varargin)

    plot_title = [];
    sensitivity = 30;
    visible = false;    
    width = 6;
    height = 4;

    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'title'
                plot_title = varargin{i+1};
            case 'sensitivity'
                sensitivity = varargin{i+1};
            case 'visible'
                visible = varargin{i+1};    
            case 'width'
                width = varargin{i+1};
            case 'height'
                height = varargin{i+1};
            otherwise 
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end 

    if ~visible
        hf = figure('Visible', 'off');
    else
        hf = figure();
    end

    hold on;
    grid on;
    
    if ~isempty(plot_title)
        title(plot_title, 'interpreter', 'none'); 
    end;
    available = true(length(trackers), 1);

    for t = 1:length(trackers)

        if all(isnan(accuracy(:, t)))
            available(t) = 0;
            continue;
        end;

        ar_mean = mean([accuracy(:, t), robustness(:, t)], 1);

        plot(exp(-ar_mean(2) * sensitivity), ar_mean(1), ...
            trackers{t}.style.symbol, 'Color', trackers{t}.style.color, ...
            'MarkerSize', 10, 'LineWidth', trackers{t}.style.width);

    end;
    
    tracker_labels = cellfun(@(x) x.label, trackers, 'UniformOutput', 0);

    legend(tracker_labels(available), 'Location', 'NorthWestOutside'); 
    xlabel(sprintf('Reliability (S = %d)', sensitivity));
    ylabel('Accuracy');
    xlim([0, 1]); 
    ylim([0, 1]);

    set(hf, 'PaperUnits', 'inches', 'PaperSize', [width, height], 'PaperPosition', [0, 0, width, height]);

    hold off;
