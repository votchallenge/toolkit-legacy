function answer = file_newer_than(candidate, original)
% file_newer_than Test if the first file is newer than the second file
%
% Test if the first file is newer than the second file.
%
% Input:
% - candidate (string): Path to the first file.
% - original (string): Path to the second file.
%
% Output:
% - answer (boolean): True if the first file is newer than the second one.
%


candidate_metadata  = dir(candidate);
original_metadata  = dir(original);

if size(original_metadata, 1) ~= 1 || size(candidate_metadata, 1) ~= 1
    answer = 0;
    return;
end;

answer = original_metadata.datenum <= candidate_metadata.datenum;
