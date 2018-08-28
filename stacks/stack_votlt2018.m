function experiments = stack_votlt2018()

set_global_variable('bundle', 'http://data.votchallenge.net/vot2018/longterm/description.json');

baseline.name = 'longterm';
baseline.converter = [];
baseline.type = 'unsupervised';
baseline.tags = {};

baseline.parameters.repetitions = 1;
baseline.parameters.burnin = 0;

baseline.analysis = {'precision_recall', 'speed'};

redetect.name = 'redetection';
redetect.converter = @(sequence) sequence_test_redetection(sequence, ...
    'Length', 200, 'Initialization', 5, 'Padding',2, ...
    'Scaling', 3);

redetect.type = 'unsupervised';
redetect.tags = {};

redetect.parameters.repetitions = 1;
redetect.parameters.burnin = 0;

redetect.analysis = {'redetection'};

experiments = {redetect, baseline};

end




