function [status] = delpath(root, varargin)
% delpath Deletes the file or directory recursively
%
% Deletes the file or directory. If the root is a directory then all its
% content is deleted recursively.
%
% Input:
% - root (string): Path to file or root directory to delete.
% - varargin[Empty] (boolean): Delete directory only if it is.
% - varargin[Root] (boolean): Also delete root directory.
%
% Output:
% - status (boolean): True on success.
%


    if_empty = false;
    delete_root = true;

    args = varargin;
    for j=1:2:length(args)
        switch lower(varargin{j})
            case 'empty', if_empty = args{j+1};
            case 'root', delete_root = args{j+1};
            otherwise, error(['unrecognized argument ' args{j}]);
        end
    end

    if ~exist(root, 'dir')
        if exist(root, 'file')
            delete(root);
            status = 1;
        else
            status = 0;
        end;
        return;
    end;

    status = true;

    data = dir(root);

    isdir = [data.isdir];
    files = {data(~isdir).name}';

    sdirs = {data(isdir).name};
    for sdir = find(~ismember(sdirs, {'.', '..'}))
        status = status && delpath(fullfile(root, sdirs{sdir}), 'Root', true);
    end

    if isempty(files) || ~if_empty
        if ~isempty(files)
            for i = 1:length(files)
                delete(fullfile(root, files{i}));
            end;
        end
    else
        status = false;
        return;
    end

    if (status && delete_root)
		try
		    rmdir(root);
		catch
			status = false;
		end;
    end;
