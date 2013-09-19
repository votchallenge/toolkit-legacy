function value = get_global_variable(name, default)

if ~exist('default', 'var')
    default = [];
end;

try
    eval(['global ', name]);
    if exist(name, 'var')
        eval(['empty = isempty(', name , ');']);
        if empty
            value = default;
        else
            eval(['value = ', name , ';']);
        end;
    end;
catch 
    value = default;
end;
