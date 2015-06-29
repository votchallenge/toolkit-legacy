function  relative_path = relativepath( target_path, root_path )
% relativepath Returns the relative path from an root path to the target path
%
% Returns the relative path from an root path to the target path.
% Both arguments must be strings with absolute paths.
% The actual path is optional, if omitted the current dir is used instead.
% In case the volume drive letters don't match, an absolute path will be returned.
% If a relative path is returned, it always starts with '.\' or '..\'
%
% Credit: Jochen Lenz
%
% Input:
% - target_path (string): Absolute path.
% - root_path (string, optional): Start for relative path. Defaults to current directory.
%
% Output:
% - relative_path (string): Relative path.
%


% 2nd parameter is optional:
if  nargin < 2
   root_path = cd;
end

% Predefine return string:
relative_path = '';

% Make sure strings end by a filesep character:
if  isempty(root_path)  ||   ~isequal(root_path(end),filesep)
   root_path = [root_path filesep];
end
if  isempty(target_path)  ||   ~isequal(target_path(end),filesep)
   target_path = [target_path filesep];
end

if isunix()
	[root_path] = fileparts(root_path);
	[target_path] = fileparts(target_path);
else
	% Convert to all lowercase:
	[root_path] = fileparts(lower(root_path));
	[target_path] = fileparts(lower(target_path));
end;

% Create a cell-array containing the directory levels:
act_path_cell = pathparts(root_path);
tgt_path_cell = pathparts(target_path);

% If volumes are different, return absolute path:
if  isempty(act_path_cell)  ||   isempty(tgt_path_cell)
   return  % rel_path = ''
else
   if  ~isequal( act_path_cell{1} , tgt_path_cell{1} )
      relative_path = target_path;
      return
   end
end

% Remove level by level, as long as both are equal:
while  ~isempty(act_path_cell) > 0   &&   ~isempty(tgt_path_cell)
   if  isequal( act_path_cell{1}, tgt_path_cell{1} )
      act_path_cell(1) = [];
      tgt_path_cell(1) = [];
   else
      break
   end
end

% As much levels down ('..\') as levels are remaining in "act_path":
for  i = 1 : length(act_path_cell)
   relative_path = fullfile('..', relative_path);
end

% Relative directory levels to target directory:
for  i = 1 : length(tgt_path_cell)
   relative_path = fullfile(relative_path, tgt_path_cell{i});
end

% Start with '.' or '..' :
if  isempty(relative_path)
   relative_path = ['.', filesep];
elseif  ~isequal(relative_path(1),'.')
   relative_path = fullfile('.', relative_path);
end

return

% -------------------------------------------------

function  path_cell = pathparts(path_str)

path_str = [filesep path_str filesep];
path_cell = {};

sep_pos = findstr( path_str, filesep );
for i = 1 : length(sep_pos)-1
   path_cell{i} = path_str( sep_pos(i)+1 : sep_pos(i+1)-1 );
end

return
