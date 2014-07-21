function [nspeed] = normalize_speed(speed, failures, tracker, sequence, performance)

factor = performance.convolution_native;
startup = 0;

if strcmpi(tracker.interpreter, 'matlab')
    if isfield(performance, 'matlab_startup')
        startup = performance.matlab_startup / factor;
    else
        model = get_global_variable('performance.matlab_startup_model', []);
		if ~isempty(model)
			startup = model(1) * performance.reading + model(2);
		end;
    end;
end

reading = performance.reading * 600 * 600 / (sequence.width * sequence.height);

speed(speed > performance.reading) = speed(speed > reading) - reading;

nspeed = ((speed * sequence.length) / factor - failures * startup) / sequence.length;
