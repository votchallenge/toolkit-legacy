function [working_directory] = track_prepare_trial_data(sequence, start)

% create temporary directory and generate input data
working_directory = tempname;
mkdir(working_directory);

region_file = fullfile(working_directory, 'region.txt');
images_file = fullfile(working_directory, 'images.txt');

region = track_get_region(sequence, start);

csvwrite(region_file, region);

images_fp = fopen(images_file, 'w');
for i = start:sequence.length
    image_path = track_get_image(sequence, i);
    fprintf(images_fp, '%s\n', image_path);
end;
fclose(images_fp);

