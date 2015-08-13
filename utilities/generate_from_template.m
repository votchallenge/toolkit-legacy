function generate_from_template(filename, template, varargin)
% generate_from_template Generate a new file from a template file
%
% Generate a new file from a template file by % inserting given variables 
% into the placeholders. The placeholders in the template file are denoted
% by ''{{ variable_name }}''.
%
% Input:
% - filename (string): Path to the destination file.
% - template (string): Path to the template file.
% - varargin (cell): Pairs of strings, the first string denotes the name of
% the variable and the second one denotes the value.
%


report = fileread(template);

if (ischar(filename))
    fid = fopen(filename, 'w');
    close_file = 1;
else
    fid = filename;
    close_file = 0;
end;

pS = strfind(report, '{{');
pE = strfind(report, '}}');

variables = struct(varargin{:});

for i = 1:numel(pS)
    s = pS(i);
    e = min(pE(pE > s)); 
    if isempty(e)
        break;
    end;

    varname = strtrim(report(s+2:e-1));
    varvalue = '';
    
    if isempty(varname)
        continue;
    end;
    
    if isfield(variables, varname)
        varvalue = variables.(varname);
    elseif varname(1) == '@'
        varvalue = num2str(get_global_variable(varname(2:end), ''));
    end;
    
    report = cat(2, report(1:s-1), varvalue, report(e+2:end));
    pS = pS - (e - s + 2) + numel(varvalue);
    pE = pE - (e - s + 2) + numel(varvalue);
end

fwrite(fid, report);

if (close_file)
    fclose(fid);
end;

