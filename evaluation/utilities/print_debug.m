function print_debug(text, varargin)

global track_debug;

if ~track_debug
    return;
end;

if nargin > 1
    disp(sprintf(text, varargin{:}));
else
    disp(text);
end;

if is_octave()
    fflush(stdout);
else
    drawnow('update');
end;
