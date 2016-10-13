function value = get_global_variable(name, default)
% get_global_variable Get a workspace global variable
%
% Get a global variable in a current workspace storage. If the variable
% does not exist in the storage an optional default value is returned. If
% the default value does not exist then an empty matrix is returned.
%
% If no argument is given then a structure with all global variables is
% returned.
%
% Input:
% - name (string): Name of the variable.
% - default (any): Optional default value.
%
% Output:
% - value (any): Value of variable or an empty matrix.
%


global global_variables;

if nargin < 1
   value = global_variables; 
   return;
end

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

