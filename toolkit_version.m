function version = toolkit_version()
% toolkit_version Version information for the toolkit
%
% Returns version information for the toolkit.
%
% Output:
% - version (structure): Structure containing version information.
%     - major (integer): Major version of the toolkit
%     - minor (integer): Minor version of the toolkit
%     - patch (integer): Patch version of the toolkit

version = struct('major', 0, 'minor', 0, 'patch', 0);

try

	root = fileparts(mfilename('fullpath'));

	tokens = strsplit(fileread(fullfile(root, 'VERSION')), '.');

	version.major = int32(str2double(tokens{1}));
	version.minor = int32(str2double(tokens{2}));
	version.patch = int32(str2double(tokens{3}));

catch

end

