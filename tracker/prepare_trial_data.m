function prepare_trial_data(directory, sequence, start, context)
% prepare_trial_data Prepares data for a trial run
%
% Prepares a temporary directory and populates it with necessary data for the tracker.
%
% Input:
% - directory (string): Path to directory where the data should be placed.
% - sequence (struct): Sequence structure.
% - start (integer): Offset from the start of the sequence in number of frames.
% - context (struct): Execution context structure. This structure contains parameters of the execution.

% create temporary directory and generate input data
mkpath(directory);

region_file = fullfile(directory, 'region.txt');
images_file = fullfile(directory, 'images.txt');

region = sequence.initialize(sequence, start, context);

csvwrite(region_file, region);

images_fp = fopen(images_file, 'w');
for i = start:sequence.length
    image_path = get_image(sequence, i);
    fprintf(images_fp, '%s\n', image_path);
end;
fclose(images_fp);

