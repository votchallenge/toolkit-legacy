function print_text(text, varargin)
% print_debug Prints formatted text
%
% Formats and prints text taking into account the indent level that can be adjusted using print_indent function.
%
% Input:
% - text (string): String to print.
% - varargin (cell): Additional arguments that are passed to sprintf.
%

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
