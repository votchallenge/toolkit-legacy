function [status] = recursive_rmdir(root)

    status = 1;

    data = dir(root);
    isdir = [data.isdir]; 
    files = {data(~isdir).name}';
    if ~isempty(files)
        for i = 1:length(files)
            delete(fullfile(root,files{i}));
        end;
    end

    sdirs = {data(isdir).name};
    for sdir = find(~ismember(sdirs, {'.','..'}))
        status = status && recursive_rmdir(fullfile(root, sdirs{sdir})); 
    end

    if (status)
        rmdir(root);
    end;
