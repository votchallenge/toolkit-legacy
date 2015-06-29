function [normalized_speed, actual_speed] = normalize_speed(speed, failures, skipping, tracker, sequence)
% normalize_speed Normalizes tracker speed estimate
%
% This function normalizes speed estimates based on performance profile and some information about 
% the way the measurement was obtained (sequence, number of failures, frame skipping).
%
% Input:
% - speed (double): The initial speed estimate.
% - failures (double): Number of failures of the tracker.
% - skipping (integer): Number of skipped frames after each failure.
% - tracker (structure): A valid tracker descriptor.
% - sequence (structure): A valid sequence descriptor.
%
% Output:
% - normalized_speed (double): Normalized speed estimate.
% - actual_speed (double): Corrected raw speed based on supplied information,
%

if ~isfield(tracker, 'performance')
    error('Tracker %s has no performance profile, unable to normalize speed.', tracker.identifier);
end;

performance = tracker.performance;

factor = performance.nonlinear_native;
startup = 0;

if strcmpi(tracker.interpreter, 'matlab')
    if isfield(performance, 'matlab_startup')
        startup = performance.matlab_startup;
    else
        model = get_global_variable('matlab_startup_model', []);
		if ~isempty(model)
			startup = model(1) * performance.reading + model(2);
		end;
    end;
end

failure_count = cellfun(@(x) numel(x), failures, 'UniformOutput', true);

if tracker.trax
	actual_length = sequence.length - (skipping - 1) * failure_count;
	full_length = sequence.length;
	startup_time = startup * (1 + failure_count);
else
	full_length = cellfun(@(x) sum(sequence.length - x - (skipping - 1)), failures, 'UniformOutput', true) + sequence.length;
	actual_length = full_length;
	startup_time = startup * (1 + failure_count);
end;

actual_speed = (((speed .* full_length) - startup_time) ./ actual_length);
normalized_speed = actual_speed / factor;
