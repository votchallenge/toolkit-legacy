function experiments = stack_vottir2016()

set_global_variable('bundle', 'https://liu.box.com/shared/static/yjbd38x42gkvovdidk2je01n0ymk2842.zip');

baseline.name = 'baseline';
baseline.converter = [];
baseline.type = 'supervised';
baseline.labels = {'camera_motion', 'dynamics_change', 'occlusion', 'size_change', 'motion_change', 'empty'};
               
baseline.parameters.repetitions = 15;
baseline.parameters.burnin = 10;
baseline.parameters.skip_initialize = 5;
baseline.parameters.failure_overlap = 0;

experiments = {baseline};

end
