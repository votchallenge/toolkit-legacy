function print_debug(text, varargin)
% print_debug Prints formatted debug text
%
% Formats and prints text if global debug option is enabled.
%
% Input:
% - text (string): String to print.
% - varargin (cell): Additional arguments that are passed to sprintf.
%


if ~get_global_variable('debug', 0)
    return;
end;

print_text(text, varargin{:});
