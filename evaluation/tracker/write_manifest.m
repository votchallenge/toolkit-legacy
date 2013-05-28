function [manifest] = write_manifest(tracker)

mkpath(tracker.directory);

manifest = fullfile(tracker.directory, 'manifest.txt');

fid = fopen(manifest, 'w');

fprintf(fid, 'toolkit.version=%d\n', toolkit_information());
fprintf(fid, 'tracker.identifier=%s\n', tracker.identifier);
fprintf(fid, 'timestamp=%s\n', datestr(now, 31));


fclose(fid);
