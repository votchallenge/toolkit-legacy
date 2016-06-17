function experiments = stack_vot2013_extra()

set_global_variable('bundle', 'http://box.vicos.si/vot/vot2013.zip');
set_global_variable('legacy_rasterization', true);
set_global_variable('bounded_overlap', false);

basic_experiments = stack_vot2013();

loss_black.name = 'loss_black';
loss_black.converter = @(x) sequence_pixelchange(x, @(I, L, i, len) ...
    deal(iff(mod(i, 5) == 0, zeros(size(I)), I), iff(mod(i, 5) == 0, ...
    union(L, {'hidden'}), L)), 'loss_black');
loss_black.type = 'supervised';
loss_black.labels = {'camera_motion', 'illum_change', 'occlusion', 'size', ...
    'motion', 'empty'};
loss_black.parameters.repetitions = 15;
loss_black.parameters.burnin = 10;
loss_black.parameters.skip_initialize = 5;
loss_black.parameters.skip_labels = {'hidden'};
loss_black.parameters.failure_overlap = 0;

skipping.name = 'skipping';
skipping.converter = @(s) sequence_skipping(s, 2, 2);
skipping.type = 'supervised';
skipping.labels = {'camera_motion', 'illum_change', 'occlusion', 'size', ...
    'motion', 'empty'};
skipping.parameters.repetitions = 15;
skipping.parameters.burnin = 10;
skipping.parameters.skip_initialize = 5;
skipping.parameters.failure_overlap = 0;

resize.name = 'resize';
resize.converter = @(s) sequence_resize(s, 0.6);
resize.type = 'supervised';
resize.labels = {'camera_motion', 'illum_change', 'occlusion', 'size', ...
    'motion', 'empty'};
resize.parameters.repetitions = 15;
resize.parameters.burnin = 10;
resize.parameters.skip_initialize = 5;
resize.parameters.failure_overlap = 0;

reverse.name = 'reverse';
reverse.converter = 'sequence_reverse';
reverse.type = 'supervised';
reverse.labels = {'camera_motion', 'illum_change', 'occlusion', 'size', ...
    'motion', 'empty'};
reverse.parameters.repetitions = 15;
reverse.parameters.burnin = 10;
reverse.parameters.skip_initialize = 5;
reverse.parameters.failure_overlap = 0;

experiments = {loss_black, skipping, resize, reverse}; 

experiments = [basic_experiments, experiments];
