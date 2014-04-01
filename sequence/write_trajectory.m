function write_trajectory(filename, trajectory)

fid = fopen(filename, 'w');

for i = 1:length(trajectory)

    region = trajectory{i};
    
    if isnumeric(region) 
        if numel(region) == 4
            fprintf(fid, '%.2f,%.2f,%.2f,%.2f\n', region(1), region(2), ...
                region(3), region(4));

        elseif size(region, 1) > 2 && size(region, 2) == 2

            fprintf(fid, '%.2f,%.2f', region(1, 1), region(1, 2));
            for j = 2:size(region, 1)
                fprintf(fid, ',%.2f,%.2f', region(j, 1), region(j, 2));
            end;
            fprintf(fid, '\n');

        elseif numel(region) == 1
            
            fprintf(fid, '%d\n', round(region));   
            
        end;
    end;
end;

fclose(fid);