function draw_region(region, color, width)

if isnumeric(region) 
	if numel(region) == 4

        for i = 1:size(region, 1)
            x = [region(i, 1), region(i, 1), region(i, 1) + region(i, 3), ...
                 region(i, 1) + region(i, 3), region(i, 1)];
            y = [region(i, 2), region(i, 2) + region(i, 4), region(i, 2) + ...
                 region(i, 4), region(i, 2), region(i, 2)];

            plot(x, y, 'Color', color, 'LineWidth', width);
        end;

    elseif size(region, 1) > 2 && size(region, 2) == 2

        x = region(1:2:end);
        y = region(2:2:end);

        plot(x, y, 'Color', color, 'LineWidth', width);
	end;
        
end;
