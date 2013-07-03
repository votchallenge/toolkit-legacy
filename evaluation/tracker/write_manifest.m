function [manifest] = write_manifest(tracker)

mkpath(tracker.directory);

manifest = fullfile(tracker.directory, 'manifest.txt');

[platform_str,platform_maxsize,platform_endian] = computer();

if is_octave()
    environment = 'octave';
else
    environment = 'matlab';
end;

environment_version = version();

fid = fopen(manifest, 'w');

fprintf(fid, 'toolkit.version=%d\n', toolkit_information());
fprintf(fid, 'tracker.identifier=%s\n', tracker.identifier);
fprintf(fid, 'timestamp=%s\n', datestr(now, 31));
fprintf(fid, 'platfrom=%s\n', platform_str);
fprintf(fid, 'platfrom.maxsize=%f\n', platform_maxsize);
fprintf(fid, 'platfrom.endian=%s\n', platform_endian);
fprintf(fid, 'environment=%s\n', environment);
fprintf(fid, 'environment.version=%f\n', environment_version);

fclose(fid);
