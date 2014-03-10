function [result] = mkpath(filepath)

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

