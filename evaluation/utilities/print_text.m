function print_text(text, varargin)

global track_properties;

if track_properties.indent > 0
    fprintf(repmat(sprintf('  '), 1, track_properties.indent));
end;

if ispc
    text = strrep(text, '\', '\\');
end

if nargin > 1
    fprintf([text, '\n'], varargin{:});
else
    fprintf([text, '\n']);
end;

if is_octave()
    fflush(stdout);
else
    drawnow('update');
end;
