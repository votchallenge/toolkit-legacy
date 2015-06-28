function [resultfile] = pack_results(tracker, sequences, experiments, varargin)
% pack_results Packs results of a tracker to an archive
%
% Creates an archive of all results for a given tracker on a set of sequences and a set of
% experiments.
%
% Input:
% - tracker (structure): A valid tracker structure.
% - sequences (cell or structure): Array of sequence structures.
% - experiments (cell or structure): Array of experiment structures.
% - varargin[Validate] (boolean): Should the results be validated for completeness.
%
% Output:
% - resultfile (string): Path to the resulting archive.
%

validate = false;

for j=1:2:length(varargin)
    switch lower(varargin{j})
        case 'validate', validate = varargin{j+1};         
        otherwise, error(['unrecognized argument ' varargin{j}]);
    end
end

files = cell(0);

for j = 1:length(experiments)
    experiment_directory = fullfile(tracker.directory, experiments{j}.name);
    if ~exist(experiment_directory, 'dir')
        continue;
    end;
    print_debug('Scanning "%s" ...', experiment_directory);
    for i = 1:length(sequences)
        sequence_directory = fullfile(experiment_directory, sequences{i}.name);
        if exist(sequence_directory, 'dir')
            files{end+1} = fullfile(sequence_directory); %#ok<AGROW>
            print_debug('Adding "%s" ...', sequence_directory);
        end;
    end;
end;

files{end+1} = write_manifest(tracker);

files{end+1} = benchmark_hardware(tracker);

filename = sprintf('%s-%s.zip', tracker.identifier, datestr(now, 30));

resultfile = fullfile(get_global_variable('directory'), filename);

resultsdir = fullfile(get_global_variable('directory'), 'results');

files = cellfun(@(f) relativepath(f, resultsdir), files, 'UniformOutput', false);

try    
    
    zip(filename, files, resultsdir);

catch e

    print_debug('Warning: error during creation of a result package: %s', e.message);
    resultfile = [];

end;


