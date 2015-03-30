function experiments = stack_vot2014()

set_global_variable('bundle', 'http://box.vicos.si/vot/vot2014.zip');
set_global_variable('repeat', 15);
set_global_variable('burnin', 10);
set_global_variable('skipping', 5);

baseline.name = 'baseline';
baseline.converter = [];
baseline.execution = 'default';
baseline.labels = {'camera_motion', 'illum_change', 'occlusion', 'size_change', ...
    'motion_change', 'empty'};
baseline.parameters.repeat = 15;
baseline.parameters.burnin = 10;
baseline.parameters.skipping = 5;

region_noise.name = 'region_noise';
region_noise.converter = @(sequence) sequence_transform_initialization(...
    sequence, @noisy_transform);
region_noise.execution = 'default';
region_noise.labels = {'camera_motion', 'illum_change', 'occlusion', 'size_change', ...
    'motion_change', 'empty'};
region_noise.parameters.repeat = 15;
region_noise.parameters.burnin = 10;
region_noise.parameters.skipping = 5;

experiments = {baseline, region_noise};

end

function [transform] = noisy_transform(sequence, index, context)

    bounds = region_convert(get_region(sequence, index), 'rectangle');

    scale = 0.9 + rand(1, 2) * 0.2;
    move = bounds(3:4) .* (0.1 - rand(1, 2) * 0.2);
    rotate = 0.1 - rand(1) * 0.2; 
    
    transform = [scale(1) * cos(rotate),  -sin(rotate), move(1); ...
         sin(rotate), scale(2) * cos(rotate), move(2); 0, 0, 1];

end