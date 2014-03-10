function generate_from_template(filename, template, varargin)

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

