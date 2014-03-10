% Checks if the environment is GNU/Octave or MatLab
% returns 1 if the environment is GNU/Octave
%         0 if the environment is Matlab
function [inOctave] = is_octave()
try
    OCTAVE_VERSION;
    inOctave = 1;
catch
    inOctave = 0;
end