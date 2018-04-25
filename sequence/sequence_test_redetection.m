function out_sequence = sequence_test_redetection(sequence, varargin)

new_length = 200;
init_frames = 5;
pad = 2;
enlarge_image_factor = 3;

for j=1:2:length(varargin)
    switch lower(varargin{j})
        case 'length', new_length = varargin{j+1};
        case 'initialization', init_frames = varargin{j+1};
        case 'padding', pad = varargin{j+1};
        case 'scaling', enlarge_image_factor = varargin{j+1};
        otherwise, error(['unrecognized argument ' varargin{j}]);
    end
end

cache_directory = fullfile(get_global_variable('directory'), 'cache', ...
    'redetection', sequence.name);

mkpath(cache_directory);

cache_groundtruth = fullfile(cache_directory, 'groundtruth.txt');

print_debug('Generating cached long-term check sequence ''%s''...', sequence.name);

image = imread(get_image(sequence, 1));
gt_region = sequence.groundtruth{1};
target_template = get_patch(image, gt_region, pad);

redet_img = uint8(zeros(enlarge_image_factor * size(image,1), ...
    enlarge_image_factor * size(image,2), size(image,3)));

x0 = size(redet_img,2) - size(target_template,2) + 1;
y0 = size(redet_img,1) - size(target_template,1) + 1;
x1 = size(redet_img,2);
y1 = size(redet_img,1);

redet_img(y0:y1, x0:x1, :) = target_template;

cx = (x0 + x1) / 2;
cy = (y0 + y1) / 2;
gt_x0 = round(cx - gt_region(3) / 2);
gt_y0 = round(cy - gt_region(4) / 2);
gt_redet = [gt_x0, gt_y0, gt_region(3), gt_region(4)];

img0 = uint8(zeros(size(redet_img)));
img0(1:size(image,1), 1:size(image,2), :) = image;

imwrite(img0, fullfile(cache_directory, 'init_image.jpg'));
imwrite(redet_img, fullfile(cache_directory, 'redet_image.jpg'));

sequence_length = min(new_length, sequence.length);
gt_new = cell(sequence_length, 1);
images_new = cell(sequence_length, 1);
for i = 1:sequence_length

    if i <= init_frames
        gt_new{i} = gt_region;
        images_new{i} = 'init_image.jpg';
    else
        gt_new{i} = gt_redet;
        images_new{i} = 'redet_image.jpg';
    end

end;

out_sequence = sequence;

out_sequence.images = images_new;
out_sequence.groundtruth = gt_new;
out_sequence.length = sequence_length;
out_sequence.width = size(redet_img, 2);
out_sequence.height = size(redet_img, 1);
out_sequence.indices = sequence.indices(1:sequence_length);
out_sequence.images_directory = cache_directory;

write_trajectory(cache_groundtruth, out_sequence.groundtruth);

out_sequence.tags.names = sequence.tags.names;
out_sequence.tags.data = sequence.tags.data;

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
