function visualize_analysis(sequence, varargin)

[overlapmap, failures, initializations] = analyze_trajectories(sequence, varargin{:});

figure(2);

imagesc(overlapmap);
colormap jet;

hold on;

plot(failures(:, 2), failures(:, 1), 'wo');

plot(initializations(:, 2), initializations(:, 1), 'kx');

hold off;



