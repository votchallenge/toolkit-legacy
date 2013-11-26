function hf = generate_ranking_plot(accuracy, robustness, plot_title, plot_labels, plot_style, plot_limit)

    hf = figure('Visible', 'off');

    hold on; box on; grid on;
    title(plot_title,'interpreter','none');

    available = true(length(plot_labels), 1);

    for t = 1:length(plot_labels)

        if isnan(accuracy(t))
            available(t) = 0;
            continue;
        end;

        plot(robustness(t), accuracy(t), plot_style{1, t}, 'Color', ...
            plot_style{2, t},'MarkerSize',10,  'LineWidth', plot_style{3, t});

    end;
    legend(plot_labels(available), 'Location', 'NorthWestOutside'); 
    xlabel('Robustness rank'); set(gca,'XDir','Reverse');
    ylabel('Accuracy rank'); set(gca,'YDir','Reverse');
    xlim([1, plot_limit]); 
    ylim([1, plot_limit]);
    hold off;
