function properties_save(directory, pattern, container)
% properties_save Save tracker runtime properties to files
%

for p = 1:numel(container.names)
    parameter_file = fullfile(directory, sprintf('%s_%s.value', pattern, container.names{p}));

    fp = fopen(parameter_file, 'w');

    for i = 1:size(container.data, 1)
        if isnumeric(container.data{i, p})
            fprintf(fp, '%f\n', container.data{i, p});
        else
            fprintf(fp, '%s\n', container.data{i, p});
        end;

    end;

    fclose(fp);

end;

