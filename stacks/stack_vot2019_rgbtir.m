function experiments = stack_vot2019_rgbtir()

set_global_variable('bundle', 'http://data.votchallenge.net/vot2019/rgbtir/meta/description.json');

baseline.name = 'baseline';
baseline.converter = [];
baseline.type = 'supervised';
baseline.tags = {'camera_motion', 'dynamics_change', 'occlusion', 'size_change', 'motion_change', 'empty'};

baseline.parameters.repetitions = 15;
baseline.parameters.burnin = 10;
baseline.parameters.skip_initialize = 5;
baseline.parameters.failure_overlap = 0;

baseline.analysis = {'expected_overlap', 'ar'};

experiments = {baseline};

end

