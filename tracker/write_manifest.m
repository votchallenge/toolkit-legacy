function [manifest] = write_manifest(tracker, directory)
% write_manifest Write a manifest file for the tracker
%
% Write a manifest file for the tracker. The manifest file contains some system
% statistics that can be used for debugging and analysis.
%
% Input:
% - tracker: Tracker structure.
% - tracker: Optional directory (default is tracker result root).
%
% Output:
% - manifest: Full path to the manifest file that is located in tracker result directory.

if nargin < 2
    directory = tracker.directory;
end;

mkpath(directory);
manifest = fullfile(directory, 'manifest.txt');

[platform_str, platform_maxsize, platform_endian] = computer();

if is_octave()
    environment = 'octave';
else
    environment = 'matlab';
end;

if tracker.trax
    protocol = 'trax';
else
    protocol = 'file';
end;

environment_version = version();

fid = fopen(manifest, 'w');

votversion = toolkit_version();

fprintf(fid, 'toolkit.version=%d.%d\n', votversion.major, votversion.minor);
if isfield(votversion, 'build')
fprintf(fid, 'toolkit.build=%d\n', votversion.build);
end;
fprintf(fid, 'toolkit.mex.hash=%s\n', get_global_variable('native_component_vot', 'unknown'));
fprintf(fid, 'toolkit.trax.hash=%s\n', get_global_variable('native_component_trax', 'unknown'));
fprintf(fid, 'tracker.identifier=%s\n', tracker.identifier);
fprintf(fid, 'tracker.protocol=%s\n', protocol);
fprintf(fid, 'tracker.interpreter=%s\n', tracker.interpreter);
fprintf(fid, 'timestamp=%s\n', datestr(now, 31));
fprintf(fid, 'platform=%s\n', platform_str);
fprintf(fid, 'platform.maxsize=%f\n', platform_maxsize);
fprintf(fid, 'platform.endian=%s\n', platform_endian);
fprintf(fid, 'environment=%s\n', environment);
fprintf(fid, 'environment.version=%s\n', environment_version);

fclose(fid);
