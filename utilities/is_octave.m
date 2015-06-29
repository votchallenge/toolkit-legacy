function [inOctave] = is_octave()
% is_octave Test if in GNU/Octave or Matlab
%
% The function returns true only if it is run in GNU/Octave.
%
% Output:
% - inOctave (boolean): True if run in GUN/Octave, false if run in Matlab.
%

try
    OCTAVE_VERSION;
    inOctave = 1;
catch
    inOctave = 0;
end
