function experiments = stack_vot2013_extra()

set_global_variable('bundle', 'http://box.vicos.si/vot/vot2013.zip');
set_global_variable('repeat', 15);
set_global_variable('burnin', 10);
set_global_variable('skipping', 5);

basic_experiments = stack_vot2013();

loss_black.name = 'loss_black';
loss_black.converter = @(x) sequence_pixelchange(x, @(I, L, i, len) ...
    deal(iff(mod(i, 5) == 0, zeros(size(I)), I), iff(mod(i, 5) == 0, ...
    union(L, {'hidden'}), L)), 'loss_black');
loss_black.execution = 'default';
loss_black.labels = {'camera_motion', 'illum_change', 'occlusion', 'size', ...
    'motion', 'empty'};
loss_black.parameters.repeat = 15;
loss_black.parameters.burnin = 10;
loss_black.parameters.skipping = 5;

skipping.name = 'skipping';
skipping.converter = @(s) sequence_skipping(s, 2, 2);
skipping.execution = 'default';
skipping.labels = {'camera_motion', 'illum_change', 'occlusion', 'size', ...
    'motion', 'empty'};
skipping.parameters.repeat = 15;
skipping.parameters.burnin = 10;
skipping.parameters.skipping = 5;

resize.name = 'resize';
resize.converter = @(s) sequence_resize(s, 0.6);
resize.execution = 'default';
resize.labels = {'camera_motion', 'illum_change', 'occlusion', 'size', ...
    'motion', 'empty'};
resize.parameters.repeat = 15;
resize.parameters.burnin = 10;
resize.parameters.skipping = 5;

reverse.name = 'reverse';
reverse.converter = 'sequence_reverse';
reverse.execution = 'default';
reverse.labels = {'camera_motion', 'illum_change', 'occlusion', 'size', ...
    'motion', 'empty'};
reverse.parameters.repeat = 15;
reverse.parameters.burnin = 10;
reverse.parameters.skipping = 5;

experiments = {loss_black, skipping, resize, reverse}; 

experiments = [basic_experiments, experiments];
