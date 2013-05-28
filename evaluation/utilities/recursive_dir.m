function [list] = recursive_dir(root)

    data = dir(root); 
    isdir = [data.isdir]; 
    files = {data(~isdir).name}';  
    if ~isempty(files)
        list = cellfun(@(x) fullfile(root,x), files,'UniformOutput',false);
    end

    sdirs = {data(isdir).name};
    for sdir = find(~ismember(sdirs, {'.','..'}))
        list = [list; recursive_dir(fullfile(root, sdirs{sdir}))]; 
    end

