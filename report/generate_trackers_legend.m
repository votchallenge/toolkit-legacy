function hf = generate_trackers_legend(trackers, x, y)

    [Y, X] = meshgrid(0:x-1, 0:y-1);
    
    hf = figure();%'Visible', 'off');

    hold on; 

    for t = 1:length(trackers)

        plot(X(t), Y(t), trackers{t}.style.symbol, 'Color', ...
            trackers{t}.style.color, 'MarkerSize', 10,  'LineWidth', trackers{t}.style.width);

        text(X(t) + 0.2, Y(t), trackers{t}.label, 'Interpreter', 'none');
        
    end;
	set(gca,'YDir','reverse');
    box off; grid off; axis off;


    hold off;
