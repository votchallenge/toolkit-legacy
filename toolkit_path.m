function toolkit_path()
% toolkit_path Appends all toolkit directories to the Matlab path
%
% Appends all toolkit directories to the Matlab path.

script_directory = fileparts(mfilename('fullpath'));
include_dirs = cellfun(@(x) fullfile(script_directory,x), {'', 'utilities', ...
    'workspace', 'tracker', 'sequence', 'stacks' ,'report', 'analysis'}, 'UniformOutput', false); 
addpath(include_dirs{:});


