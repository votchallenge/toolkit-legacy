function hf = generate_ranking_plot(trackers, accuracy, robustness, plot_title, plot_limit)

    hf = figure('Visible', 'off');

    hold on; box on; grid on;
    title(plot_title, 'interpreter','none');

    available = true(length(trackers), 1);

    for t = 1:length(trackers)

        if isnan(accuracy(t))
            available(t) = 0;
            continue;
        end;

        plot(robustness(t), accuracy(t), trackers{t}.style.symbol, 'Color', ...
            trackers{t}.style.color, 'MarkerSize',10,  'LineWidth', trackers{t}.style.width);

    end;
    plot_labels = cellfun(@(tracker) tracker.label, trackers, 'UniformOutput', 0);
    legend(plot_labels(available), 'Location', 'NorthWestOutside', 'interpreter', 'none', 'FontSize', 9); 
    xlabel('Robustness rank'); set(gca,'XDir','Reverse');
    ylabel('Accuracy rank'); set(gca,'YDir','Reverse');
    xlim([1, plot_limit]); 
    ylim([1, plot_limit]);
    hold off;
