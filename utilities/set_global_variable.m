function set_global_variable(name, value)

global global_variables;

if isempty(global_variables);
    global_variables = struct();
end;

if nargin == 1
    if isfield(global_variables, name)
        global_variables = rmfield(global_variables, name);
    end;
else
    global_variables.(name) = value;
end;

