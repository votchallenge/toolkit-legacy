function experiments = stack_test()

set_global_variable('bundle', 'http://box.vicos.si/vot/test.zip');

baseline.name = 'baseline';
baseline.converter = [];
baseline.type = 'supervised';
baseline.labels = {'camera_motion', 'illum_change', 'occlusion', 'size', ...
    'motion', 'empty'};
baseline.parameters.repetitions = 5;
baseline.parameters.burnin = 10;
baseline.parameters.skip_initialize = 5;
baseline.parameters.failure_overlap = 0;

experiments = {baseline};

end

