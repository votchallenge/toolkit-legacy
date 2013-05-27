function print_debug(text, varargin)

global track_properties;

if ~track_properties.debug
    return;
end;

print_text(text, varargin{:});
