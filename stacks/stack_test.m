function experiments = stack_test()

set_global_variable('bundle', 'http://data.votchallenge.net/toolkit/test.zip');

baseline.name = 'baseline';
baseline.converter = [];
baseline.type = 'supervised';
baseline.tags = {'camera_motion', 'illum_change', 'occlusion', 'size', ...
    'motion', 'empty'};
baseline.parameters.repetitions = 5;
baseline.parameters.burnin = 10;
baseline.parameters.skip_initialize = 5;
baseline.parameters.failure_overlap = 0;

baseline.analysis = {'expected_overlap', 'ar', 'speed'};


realtime.name = 'realtime';
realtime.converter = [];
realtime.type = 'realtime';
realtime.tags = {'camera_motion', 'illum_change', 'occlusion', 'size', ...
    'motion', 'empty'};
realtime.parameters.repetitions = 5;
realtime.parameters.burnin = 10;
realtime.parameters.skip_initialize = 5;
realtime.parameters.failure_overlap = 0;
realtime.parameters.fps_override = true;
realtime.parameters.fps_default = 20;

realtime.analysis = {'expected_overlap'};

experiments = {baseline, realtime};

end

