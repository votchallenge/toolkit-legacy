function [s] = readstruct(filename, defaults)
% readstruct Read a key-value file to a structure
%
% This function reads a key-value file to a structure. If possible, the
% values are converted to numbers, otherwise the value is kept as string.
%
% Input:
% - filename (string): Path to the file.
% - defaults (struct): A structure merged with read data, can be used to
%   set defaults.
%
% Output:
% - s (structure): Resulting structure.
%


fid = fopen(filename);
lines = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);

lines = lines{1};

s = struct();

for i = 1:numel(lines)
	[key, value] = parse_line(lines{i});

	key = strrep(strrep(strrep(key, '.', '_'), ' ', '_'), '-', '_');

	if ~isempty(key)
		s.(key) = value;
	end

end;

if nargin > 1
	s = struct_merge(defaults, s);
end

end

function [key, value] = parse_line(line)

    delimiter = find(line == '=', 1);

	if isnan(delimiter)
		key = []; value = [];
		return;
	end;

	key = line(1:delimiter-1);
	value = line(delimiter+1:end);

	[numvalue, status] = str2num(value); %#ok<ST2NM>

	if status
		value = numvalue;
	end

end




