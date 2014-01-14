function value = get_global_variable(name, default)

global global_variables;

if ~exist('default', 'var')
    default = [];
end;

if isempty(global_variables);
    value = default;
    return;
end;

try
    value = global_variables.(name);
catch  %#ok<CTCH>
    value = default;
end;

return;

