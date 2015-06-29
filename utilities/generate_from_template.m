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

for i = 1:2:length(varargin)
    key = varargin{i};
    value = varargin{i+1};
    report = strrep(report, ['{{', key, '}}'], value);
end 

fwrite(fid, report);

if (close_file)
    fclose(fid);
end;

