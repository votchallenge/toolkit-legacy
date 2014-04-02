function trajectory = read_trajectory(filename)

if ~exist(filename, 'file')
    trajectory = [];
    return;
end;

fid = fopen(filename);
lines = textscan(fid, '%s', 'delimiter', '\n');
fclose(fid);

lines = lines{1};

trajectory = cell(length(lines), 1);

for i = 1:length(lines)

    parts = cellfun(@(x) str2double(x), strsplit(lines{i}, ','), 'UniformOutput', 1);

    if numel(parts) == 1
        region = parts;
    elseif length(parts) == 4
        if isnan(parts(1))
            region = - parts(4); % Support for old format
        else
            region = parts;
        end;
    elseif mod(length(parts), 2) == 0 && length(parts) > 5
        region = parts; 
    end;

    trajectory{i} = region;
end;
