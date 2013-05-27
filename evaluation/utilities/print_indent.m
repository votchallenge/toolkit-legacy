function print_indent(indent)

global track_properties;

track_properties.indent = max(0, track_properties.indent + indent);
