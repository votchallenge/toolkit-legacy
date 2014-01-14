

set_global_variable('bundle', 'http://box.vicos.si/vot/vot2013.zip');
set_global_variable('repeat', 15);
set_global_variable('burnin', 10);
set_global_variable('skipping', 5);

baseline.name = 'baseline';
baseline.converter = [];
baseline.execution = 'default';

region_noise.name = 'region_noise';
region_noise.converter = 'sequence_noisy_initialization';
region_noise.execution = 'default';

grayscale.name = 'grayscale';
grayscale.converter = 'sequence_grayscale';
grayscale.execution = 'default';

experiments = {baseline, region_noise, grayscale};

