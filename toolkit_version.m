function version = toolkit_version(compare)
% toolkit_version Version information for the toolkit, compare
% versions
%
% Returns version information for the toolkit.
%
% Input:
% - compare (string, optional): a version to compare against, if set
%   then the string is parsed and compared against toolkit version,
%   -1 is returned if it is lower, 1 if higher and 0 if equal.
%
% Output:
% - version (structure): Structure containing version information.
%     - major (integer): Major version of the toolkit
%     - minor (integer): Minor version of the toolkit
%     - patch (integer): Patch version of the toolkit

version = get_global_variable('toolkit_version');

if isempty(version)

version = struct('major', 0, 'minor', 0, 'patch', 0);

try

	root = fileparts(mfilename('fullpath'));

	tokens = strsplit(fileread(fullfile(root, 'VERSION')), '.');

	version.major = int32(str2double(tokens{1}));
	version.minor = int32(str2double(tokens{2}));
	version.patch = int32(str2double(tokens{3}));

    set_global_variable('toolkit_version', version);
    
catch
    error('Unable to parse version file');
end

end;

if nargin > 0
    
    tokens = strsplit(strtrim(compare), '.');
    
    compare = struct('major', 0, 'minor', 0, 'patch', 0);
    
    if numel(compare) < 1
        error('Illegal version');
    end;
    
    try
    
        if numel(tokens) > 0
           compare.major =  int32(str2double(tokens{1}));
        end
        if numel(tokens) > 1
           compare.minor =  int32(str2double(tokens{2}));
        end
        if numel(tokens) > 2
           compare.patch =  int32(str2double(tokens{3}));
        end
    
    catch
        error('Unable to parse version string');
    end
    
    if version.major > compare.major; version = -1; return; end;
    if version.major < compare.major; version = 1; return; end;
    if version.minor > compare.minor; version = -1; return; end;
    if version.minor < compare.minor; version = 1; return; end;
    if version.patch > compare.patch; version = -1; return; end;
    if version.patch < compare.patch; version = 1; return; end;
    
    version = 0;
    
end