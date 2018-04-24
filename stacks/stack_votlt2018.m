function experiments = stack_votlt2018()

set_global_variable('bundle', 'http://data.votchallenge.net/vot2018/longterm/description.json');

longterm.name = 'longterm';
longterm.converter = [];
longterm.type = 'unsupervised';
longterm.tags = {};

longterm.parameters.repetitions = 1;
longterm.parameters.burnin = 0;

longterm.analysis = {'overlap', 'speed'};

% redetection experiment
% parameter for frame modification
new_length = 200;
init_frames = 5;
pad = 2;
enlarge_image_factor = 3;

redetect.name = 'redetection';
redetect.converter = @(sequence) sequence_redetection(sequence, ...
    'new_length',new_length, 'init_frames',init_frames, 'pad',pad, ...
    'enlarge_image_factor',enlarge_image_factor);

redetect.type = 'unsupervised';
redetect.tags = {};

redetect.parameters.repetitions = 1;
redetect.parameters.burnin = 0;

redetect.analysis = {'overlap', 'speed'};


experiments = {redetect, longterm};

end




