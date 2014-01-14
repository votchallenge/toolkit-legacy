function print_text(text, varargin)

indent = get_global_variable('indent', 0);

if indent > 0
    fprintf(repmat(sprintf('  '), 1, indent));
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
