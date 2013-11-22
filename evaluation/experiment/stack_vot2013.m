
global track_properties;

track_properties.bundle = 'http://box.vicos.si/vot/vot2013.zip';
track_properties.repeat = 15;
track_properties.burnin = 10;
track_properties.skipping = 5;

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

