function set_global_variable(name, value)

global global_variables;

if isempty(global_variables);
    global_variables = struct();
end;

global_variables.(name) = value;

