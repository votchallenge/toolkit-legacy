function out_sequence = sequence_test_redetection(sequence, varargin)

new_length = 200;
init_frames = 5;
padding = 2;
enlarge_image_factor = 3;

for j=1:2:length(varargin)
    switch lower(varargin{j})
        case 'length', new_length = varargin{j+1};
        case 'initialization', init_frames = varargin{j+1};
        case 'padding', padding = varargin{j+1};
        case 'scaling', enlarge_image_factor = varargin{j+1};
        otherwise, error(['unrecognized argument ' varargin{j}]);
    end
end

cache_directory = fullfile(get_global_variable('directory'), 'cache', ...
    'redetection', sequence.name);

mkpath(cache_directory);

cache_groundtruth = fullfile(cache_directory, 'groundtruth.txt');

if ~exist(cache_groundtruth, 'file')

    print_debug('Generating cached long-term check sequence ''%s''...', sequence.name);

    image = imread(sequence_get_image(sequence, 1));
    initial_region = sequence.groundtruth{1};
    target_template = get_patch(image, initial_region, padding);

    redetection_image = uint8(zeros(enlarge_image_factor * size(image,1), ...
        enlarge_image_factor * size(image,2), size(image,3)));

    x0 = size(redetection_image,2) - size(target_template,2) + 1;
    y0 = size(redetection_image,1) - size(target_template,1) + 1;
    x1 = size(redetection_image,2);
    y1 = size(redetection_image,1);

    redetection_image(y0:y1, x0:x1, :) = target_template;

    cx = (x0 + x1) / 2;
    cy = (y0 + y1) / 2;
    gt_x0 = round(cx - initial_region(3) / 2);
    gt_y0 = round(cy - initial_region(4) / 2);
    redetection_region = [gt_x0, gt_y0, initial_region(3), initial_region(4)];

    initial_image = uint8(zeros(size(redetection_image)));
    initial_image(1:size(image,1), 1:size(image,2), :) = image;

    imwrite(initial_image, fullfile(cache_directory, 'initial.jpg'));
    imwrite(redetection_image, fullfile(cache_directory, 'redetection.jpg'));

    write_trajectory(cache_groundtruth, {initial_region, redetection_region});
    
end;

sequence_length = min(new_length, sequence.length);

image = imread(fullfile(cache_directory, 'initial.jpg'));

groundtruth = read_trajectory(cache_groundtruth);

groundtruth = cat(1, repmat(groundtruth(1), init_frames, 1), ...
    repmat(groundtruth(2), sequence_length - init_frames, 1));
images = cat(1, repmat({'initial.jpg'}, init_frames, 1), ...
    repmat({'redetection.jpg'}, sequence_length - init_frames, 1));

out_sequence = sequence;
out_sequence.images = images;
out_sequence.groundtruth = groundtruth;
out_sequence.length = sequence_length;
out_sequence.width = size(image, 2);
out_sequence.height = size(image, 1);
out_sequence.indices = sequence.indices(1:sequence_length);
out_sequence.images_directory = cache_directory;

end


function patch = get_patch(im, rect, pad)

W = round(max(rect(3), rect(4)) * pad);
H = W;

cx = rect(1) + rect(3) / 2;
cy = rect(2) + rect(4) / 2;

xs = floor(cx) + (1:W) - floor(W/2);
ys = floor(cy) + (1:H) - floor(H/2);

xs(xs < 1) = 1;
ys(ys < 1) = 1;
xs(xs > size(im,2)) = size(im,2);
ys(ys > size(im,1)) = size(im,1);

patch = im(ys, xs, :);

pw = 7;
win_x = ((1 - abs(linspace(-1,1,size(patch,2))).^pw).^pw);
win_y = ((1 - abs(linspace(-1,1,size(patch,1))).^pw).^pw);
win_img = win_y'*win_x;

patch = uint8(bsxfun(@times, single(patch), win_img));

end  % endfunction
