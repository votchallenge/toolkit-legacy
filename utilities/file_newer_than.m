function answer = file_newer_than(candidate, original)

candidate_metadata  = dir(candidate);
original_metadata  = dir(original);

if size(original_metadata, 1) ~= 1 || size(candidate_metadata, 1) ~= 1
    answer = 0;
    return;
end;

answer = original_metadata.datenum <= candidate_metadata.datenum;
