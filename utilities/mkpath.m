function [result] = mkpath(filepath)
% mkpath Creates a directory path
%
% Creates a given path by recurively adding directories.
%
% Input:
% - filepath (string): A path to create.
%
% Output:
% - result (boolean): True if successful.
%


if exist(filepath) == 2
    result = 0;
    return;
end;

if exist(filepath) == 7
    result = 1;
    return;
end;

result = mkpath(fileparts(filepath));

if ~result
    return;
end;

result = mkdir(filepath);

