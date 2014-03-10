function print_debug(text, varargin)

if ~get_global_variable('debug', 0)
    return;
end;

print_text(text, varargin{:});
