function [trajectory, time] = track_trial(tracker, sequence, start)

confirm_recursive_rmdir(0, "local");

% create temporary directory and generate input data
working_directory = tempname;
mkdir(working_directory);

region_file = fullfile(working_directory, 'region.txt');
images_file = fullfile(working_directory, 'images.txt');
output_file = fullfile(working_directory, 'output.txt');

region = track_get_region(sequence, start);

csvwrite(region_file, region);

images_fp = fopen(images_file, 'w');
for i = start:sequence.length
    image_path = track_get_image(sequence, i);
    fprintf(images_fp, '%s\n', image_path);
end;
fclose(images_fp);

% run the tracker

old_directory = pwd;

try

    cd(working_directory);

    tic;
    [status] = system(tracker.command);
    time = toc;

    if status ~= 0

    end;

catch e

end;

cd(old_directory);

% validate and process results

if exist(output_file, 'file')
    trajectory = double(csvread(output_file));

    [n_frames, n_values] = size(trajectory);

    if n_values ~= 4
        trajectory = [];
    end;

    if (n_frames ~= (sequence.length-start) + 1)
        trajectory = [];
        time = NaN;
    end;

else
    trajectory = [];
    time = NaN;
end;

% clean-up temporary directory

rmdir(working_directory, 's');

