function hf = generate_ar_plot(trackers, accuracy, robustness, varargin)

    plot_title = [];
    sensitivity = 30;
    visible = false;    
    width = [];
    height = [];

    hf = [];
    
    plot_callback = @default_plot_ar;
    
    show_legend = true;
    
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
            case 'callback'
                plot_callback = varargin{i+1};
            case 'handle'
                hf = varargin{i+1};
            case 'legend'
                show_legend = varargin{i+1};                    
            otherwise 
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end 

    if isempty(width)
        width = iff(show_legend, 6, 4);
    end

    if isempty(height)
        height = 4;
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

    hold on; box on; grid on;
    
    if ~isempty(plot_title)
        title(plot_title, 'interpreter', 'none'); 
    end;
    available = true(length(trackers), 1);

    for t = 1:length(trackers)

        if all(isnan(accuracy(:, t, :)))
            available(t) = 0;
            continue;
        end;

        ar_mean = squeeze(mean([accuracy(:, t, :), robustness(:, t, :)], 1));
        
        if size(ar_mean, 1) == 1
            plot_robustness = exp(-ar_mean(2) * sensitivity);
            plot_accuracy = ar_mean(1);
        else
            plot_robustness = exp(-ar_mean(2, :) * sensitivity);
            plot_accuracy = ar_mean(1, :);   
            
        end;
        
        plot_callback(plot_robustness, plot_accuracy, ...
                trackers{t}.style.symbol, trackers{t}.style.color, ...
                trackers{t}.style.width);
        
    end;
    
    tracker_labels = cellfun(@(x) x.label, trackers, 'UniformOutput', 0);

    if show_legend
        legend(tracker_labels(available), 'Location', 'NorthWestOutside', 'interpreter', 'none'); 
    end;
    
    xlabel(sprintf('Robustness (S = %.2f)', sensitivity));
    ylabel('Accuracy');
    xlim([0, 1]); 
    ylim([0, 1]);

    set(hf, 'PaperUnits', 'inches', 'PaperSize', [width, height], 'PaperPosition', [0, 0, width, height]);

    hold off;
    
end

function default_plot_ar(robustness, accuracy, symbol, color, width)

    plot(robustness, accuracy, symbol, 'Color', color, ...
        'MarkerSize', 10, 'LineWidth', width);

end
