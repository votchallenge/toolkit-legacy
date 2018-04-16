function experiments = stack_vot2015()

set_global_variable('bundle', 'http://data.votchallenge.net/vot2015/dataset/description.json');
set_global_variable('legacy_rasterization', true);
set_global_variable('bounded_overlap', false);

baseline.name = 'baseline';
baseline.converter = [];
baseline.type = 'supervised';
baseline.tags = {'camera_motion', 'illum_change', 'occlusion', 'size_change', 'motion_change', 'empty'};

baseline.parameters.repetitions = 15;
baseline.parameters.burnin = 10;
baseline.parameters.skip_initialize = 5;
baseline.parameters.failure_overlap = 0;

baseline.analysis = {'ar', 'expected_overlap', 'speed'};

experiments = {baseline};

end

