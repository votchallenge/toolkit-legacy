function [trajectory] = load_trajectory(filename)

trajectory = [];

if exist(filename, 'file')
    trajectory = double(csvread(filename));

    [n_frames, n_values] = size(trajectory);

    if n_values ~= 4
        trajectory = [];
        print_debug('WARNING: File "%s" not valid.', filename);
    end;

else
    print_debug('WARNING: File "%s" does not exists.', filename);
end;
