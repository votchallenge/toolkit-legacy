function paths = toolkit_path()
% toolkit_path Appends all toolkit directories to the Matlab path
%
% If no output argument is given, the function appends all toolkit directories
% to the Matlab/Octave path, otherwise it returns a list as a cell array.
%
% Output:
% - paths (cell): A list of all paths.

script_directory = fileparts(mfilename('fullpath'));
include_dirs = cellfun(@(x) fullfile(script_directory, x), {'', 'utilities', ...
    'workspace', 'tracker', 'sequence', 'stacks' ,'report', 'analysis', ...
    'sequence/clustering'}, 'UniformOutput', false); 

if exist(fullfile(script_directory, 'native'), 'dir')
   include_dirs{end+1} = fullfile(script_directory, 'native');
end

if nargout > 0
    paths = include_dirs;
else
    addpath(include_dirs{:});
end;


