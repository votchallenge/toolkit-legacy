function [overlapmap, failures, initializations] = analyze_trajectories(sequence, varargin)

overlapmap = zeros(sequence.length, nargin-1);

groundtruth = get_region(sequence, 1:sequence.length);

failures = zeros(0, 2);

initializations = zeros(0, 2);

for j = 2:nargin
    if size(varargin{j-1}, 2) ~= 4 || i > size(varargin{j-1}, 1)
        continue;
    end;
    trajectory = varargin{j-1};

	overlap = calculate_overlap(trajectory, groundtruth);

	overlap(isnan(overlap)) = 0;

	overlapmap(1:min(sequence.length, length(overlap)), j-1) = overlap(1:min(sequence.length, length(overlap)));

	Fn = find(any(isnan(trajectory), 2) & trajectory(:, 4) == -1);

	In = find(any(isnan(trajectory), 2) & trajectory(:, 4) == -2);

	failures(end+1:end+length(Fn), :) = [Fn, repmat(j-1, length(Fn), 1)];

	initializations(end+1:end+length(In), :) = [In, repmat(j-1, length(In), 1)];

end;



