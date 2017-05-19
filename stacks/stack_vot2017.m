function experiments = stack_vot2017()

set_global_variable('bundle', 'http://data.votchallenge.net/vot2017/vot2017.zip');

baseline.name = 'baseline';
baseline.converter = [];
baseline.type = 'supervised';
baseline.tags = {'camera_motion', 'illum_change', 'occlusion', 'size_change', 'motion_change', 'empty'};

baseline.parameters.repetitions = 15;
baseline.parameters.burnin = 10;
baseline.parameters.skip_initialize = 5;
baseline.parameters.failure_overlap = 0;

unsupervised.name = 'unsupervised';
unsupervised.converter = [];
unsupervised.type = 'unsupervised';
unsupervised.tags = {'camera_motion', 'illum_change', 'occlusion', 'size_change', 'motion_change', 'empty'};

unsupervised.parameters.repetitions = 1;
unsupervised.parameters.burnin = 0;

realtime.name = 'realtime';
realtime.converter = [];
realtime.type = 'realtime';
realtime.tags = {'camera_motion', 'illum_change', 'occlusion', 'size_change', 'motion_change', 'empty'};

realtime.parameters.repetitions = 1;
realtime.parameters.default_fps = 20;
realtime.parameters.grace = 3;
realtime.parameters.override_fps = true;
realtime.parameters.skip_initialize = 5;
realtime.parameters.realtime_type = 'real';

experiments = {baseline, unsupervised, realtime};

end

