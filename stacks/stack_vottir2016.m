function experiments = stack_vottir2016()

set_global_variable('bundle', 'http://data.votchallenge.net/vot2016/vot-tir2016.zip');

baseline.name = 'baseline';
baseline.converter = [];
baseline.type = 'supervised';
baseline.tags = {'camera_motion', 'dynamics_change', 'occlusion', 'size_change', 'motion_change', 'empty'};

baseline.parameters.repetitions = 15;
baseline.parameters.burnin = 10;
baseline.parameters.skip_initialize = 5;
baseline.parameters.failure_overlap = 0;

experiments = {baseline};

end
