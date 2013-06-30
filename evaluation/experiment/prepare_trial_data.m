function [working_directory] = prepare_trial_data(sequence, start, context)
% PREPARE_TRIAL_DATA Prepares a temporary directory and populates it with
% necessary data for the tracker.
%
%   [DIR] = PREPARE_TRIAL_DATA(SEQUENCE, START)
%              Creates a directory and writes the image sequence and the
%              initial region file based on the sequence and the starting
%              offset.
%
%   See also RUN_TRIAL, SYSTEM.

% create temporary directory and generate input data
working_directory = tempname;
mkdir(working_directory);

region_file = fullfile(working_directory, 'region.txt');
images_file = fullfile(working_directory, 'images.txt');

region = sequence.initialize(sequence, start, context);

csvwrite(region_file, region);

images_fp = fopen(images_file, 'w');
for i = start:sequence.length
    image_path = get_image(sequence, i);
    fprintf(images_fp, '%s\n', image_path);
end;
fclose(images_fp);

