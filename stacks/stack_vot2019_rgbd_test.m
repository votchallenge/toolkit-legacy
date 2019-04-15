function experiments = stack_vot2019_rgbd_test()

set_global_variable('bundle', 'http://data.votchallenge.net/vot2019/vot19-rgbd-test.zip');
set_global_variable('trax_source_branch', 'channels');

unsupervised.name = 'rgbd-unsupervised';
unsupervised.converter = [];
unsupervised.type = 'unsupervised';
unsupervised.tags = {};

unsupervised.parameters.repetitions = 1;
unsupervised.parameters.burnin = 0;

unsupervised.analysis = {'overlap'};

experiments = {unsupervised};

end

