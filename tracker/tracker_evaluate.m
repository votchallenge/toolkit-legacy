function [files, metadata] = tracker_evaluate(tracker, sequence, experiment, varargin)
% tracker_evaluate Evaluates a tracker on a given sequence for a given experiment
%
% The core function of experimental evaluation. This function can perform various
% types of experiments or result gathering. The data is stored to the specified
% directory.
%
% Experiment types:
% - supervised: Repeats running a tracker on a given sequence for a number of
%   times, taking into account its potential deterministic nature and
%   various properties of experiments.
%
% Input:
% - tracker (struct): Tracker structure.
% - sequence (struct): Sequence structure.
% - expetiment (struct): Experiment structure.
% - varargin[Scan] (boolean): Do not evaluate the tracker but simply scan the directory
%   for files that are generated and return their list.
% - varargin[Persist] (boolean): Do not throw error even if one was encountered during
%   executuon of the experiment.
%
% Output:
% - files (cell): An array of files that were generated during the evaluation.
% - metadata (struct): Additional information about the evaluation.

    scan = false;
    files = {};
    metadata.completed = true;
    persist = false;

    for j=1:2:length(varargin)
        switch lower(varargin{j})
            case 'scan', scan = varargin{j+1};
            case 'persist', persist = varargin{j+1};
            otherwise, error(['unrecognized argument ' varargin{j}]);
        end
    end

    parameters = struct();
    if isfield(experiment, 'parameters')
        parameters = experiment.parameters;
    end;

    directory = fullfile(tracker.directory, experiment.name, sequence.name);
    mkpath(directory);

	experiment_type = experiment.type;

	if exist(['experiment_', experiment_type]) ~= 2 %#ok<EXIST>
		error('Experiment %s not available.', experiment_type);
	end;

	experiment_function = str2func(['experiment_', experiment_type]);

	try

	[files, metadata] = experiment_function(tracker, sequence, directory, parameters, scan);

	catch e
		metadata.completed = false;

		if ~persist
			rethrow(e);
		end
	end

end
