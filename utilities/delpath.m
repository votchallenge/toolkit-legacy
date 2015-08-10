function [status] = delpath(root)
% delpath Deletes the file or directory recursively
%
% Deletes the file or directory. If the root is a directory then all its
% content is deleted recursively.
%
% Input:
% - root (string): Path to file or root directory to delete.
%
% Output:
% - status (boolean): True on success.
%
    if ~exist(root, 'dir')
        status = 0;
        return;
    end;

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
        status = status && delpath(fullfile(root, sdirs{sdir})); 
    end

    if (status)
        rmdir(root);
    end;
