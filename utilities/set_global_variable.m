function set_global_variable(name, value)
% set_global_variable Set a workspace global variable
%
% Set a global variable in a current workspace storage. If a value argument
% is not given, the variable will be cleared from the storage.
%
% Input:
% - name (string): Name of the variable.
% - value (any): New value or the variable.
%


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

