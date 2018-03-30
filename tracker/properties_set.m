function container =  properties_set(container, frame, properties)
% properties_set Insert properties for a specific frame to properties container
%

if isstruct(properties)

    names = fieldnames(properties);

    for i = 1:numel(names)
        name = names{i};
        [value, numeric] = str2num(properties.(names{i})); %#ok<ST2NM>

        if ~numeric
            value = properties.(names{i});
        end;

        property_index = find(strcmp(container.names, name), 1);

        if isempty(property_index)
            property_index = numel(container.names) + 1;
            container.names{end+1} = name;
            container.data = cat(2, container.data, cell(size(container.data, 1), 1));
        end;

        container.data{frame, property_index} = value;

    end
    
elseif iscell(properties)

    for i = 1:size(properties, 1)
        name = properties{i, 1};
        [value, numeric] = str2num(properties{i, 2}); %#ok<ST2NM>

        if ~numeric
            value = properties{i, 2};
        end;

        property_index = find(strcmp(container.names, name), 1);

        if isempty(property_index)
            property_index = numel(contaner.names) + 1;
            container.names{end+1} = name;
            container.data = cat(2, container.data, cell(size(container.data, 1), 1));
        end;

        container.data{frame, property_index} = value;

    end

end;
