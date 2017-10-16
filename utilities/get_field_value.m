function value = get_field_value(structure, name, default)

if ~isstruct(structure) || ~isfield(structure, name)
    value = default;
    return;
end;

value = structure.(name);

