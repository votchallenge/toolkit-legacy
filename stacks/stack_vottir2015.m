function experiments = stack_vottir2015()

set_global_variable('bundle', 'https://liu.box.com/shared/static/4yczc0pb5uwjvvm54zfh601aj5vdz7q7.zip');

baseline.name = 'baseline';
baseline.converter = [];
baseline.type = 'supervised';
baseline.labels = {'camera_motion', 'illum_change', 'occlusion', 'size','motion', 'empty'};
               
baseline.parameters.repetitions = 15;
baseline.parameters.burnin = 10;
baseline.parameters.skip_initialize = 5;
baseline.parameters.failure_overlap = 0;

experiments = {baseline};

end

