function experiments = stack_clustering()

clustering.name = 'clustering';
clustering.converter = [];
clustering.type = 'supervised';
clustering.labels = {'camera_motion', 'illum_change', 'occlusion', 'size','motion', 'empty'};
clustering.parameters.repetitions = 1;
clustering.parameters.burnin = 10;
clustering.parameters.skip_initialize = 5;
clustering.parameters.failure_overlap = 0;

experiments = {clustering};

end