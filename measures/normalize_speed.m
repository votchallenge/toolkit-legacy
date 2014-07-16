function [nspeed] = normalize_speed(speed, failures, tracker, sequence, performance)

factor = performance.convolution_native;
startup = 0;

if strcmpi(tracker.interpreter, 'matlab')
    if isfield(performance, 'matlab_startup')
        startup = performance.matlab_startup / factor;
    else
        startup = get_global_variable('performance.matlab_startup', 0);
    end;
end

nspeed = ((speed * sequence.length) / factor - failures * startup) / sequence.length;
