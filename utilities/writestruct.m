function writestruct(filename, s)
% writestruct Store a structure to file
%
% Saves a structure object to a text file in an INI-like format.
%
% Input:
% - filename (string): Path to the file.
% - s (structure): A structure.
%

fid = fopen(filename, 'w');

writeimpl(fid, s, '');

fclose(fid);

end

function writeimpl(fid, s, prefix)

    % Extract field data
    fields = repmat(fieldnames(s), numel(s), 1);
    values = struct2cell(s);

    % Convert all numerical values to strings
    idx = cellfun(@isnumeric, values); 
    values(idx) = cellfun(@num2str, values(idx), 'UniformOutput', 0);

    for i = 1:numel(fields)
        if isstruct(values{i})
            writeimpl(fid, values{i}, [prefix, fields{i}, '.']);
        else
            fprintf(fid, '%s%s=%s\n', prefix, fields{i}, values{i});
        end
    end;
    

end