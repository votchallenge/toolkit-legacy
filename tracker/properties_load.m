function container = properties_load(directory, pattern)
% properties_load Load tracker runtime properties from files
%

candidates = dir(fullfile(directory, sprintf('%s_*.value', pattern)));

container = struct();
container.names = {};
container.data = {};

for p = 1:numel(candidates)
    
    [~, name, ~] = fileparts(candidates(p).name);
    
    parameter_name = name(length(pattern)+2:end);

    data = cell(0, 0);
    
    fp = fopen(fullfile(directory, candidates(p).name), 'r');

    while true
         line = fgets(fp);

         if line == -1
             break;
         end
         
         [value, numeric] = str2num(line(1:end-1)); %#ok<ST2NM>

         if ~numeric
            value = line(1:end-1); 
         end
         
         if isempty(value) 
             value = [];
         end;
         
         data{end+1, 1} = value; %#ok<AGROW>

    end;

    fclose(fp);

    container.names{end+1} = parameter_name;
    
    if isempty(container.data)
        container.data = data;
    else
        container.data = cat(1, container.data, data);
    end;
    
end;

