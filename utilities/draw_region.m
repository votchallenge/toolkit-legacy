function draw_region(region, color, width)

for i = 1:size(region, 1)
    x = [region(i, 1), region(i, 1), region(i, 1) + region(i, 3), ...
         region(i, 1) + region(i, 3), region(i, 1)];
    y = [region(i, 2), region(i, 2) + region(i, 4), region(i, 2) + ...
         region(i, 4), region(i, 2), region(i, 2)];

    plot(x, y, 'Color', color, 'LineWidth', width);
end;

