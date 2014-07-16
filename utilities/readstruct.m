function [s] = readstruct(filename)

fid = fopen(filename);
lines = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);

lines = lines{1};

s = struct();

for i = 1:numel(lines)
	[key, value] = parse_line(lines{i});

	if ~isempty(key)
		s.(key) = value;
	end

end;

end

function [key, value] = parse_line(line)

	tokens = strsplit(line, '=');

	if numel(tokens) < 2
		key = []; value = [];
		return;
	end;

	key = tokens{1};
	value = [tokens{2:end}];

	[numvalue, status] = str2num(value); %#ok<ST2NM>

	if status
		value = numvalue;
	end

end

