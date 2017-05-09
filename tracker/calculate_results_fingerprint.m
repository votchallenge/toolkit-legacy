function hash = calculate_results_fingerprint(tracker, experiment, sequences)
% calculate_results_fingerprint Calculate results hash
%
% Calculates a hash fingerprint based on timestamps of result files for a tracker
%
% Input:
% - tracker: Tracker structure.
% - experiment: Experiment structure.
% - sequences: Cell array of sequence structures.
%
% Output:
% - hash: A string containing hash fingerprint.

time_string = iterate(experiment, tracker, sequences, 'iterator', @fingerprint_iterator, 'context', []);

hash = md5hash(time_string);

end

function context = fingerprint_iterator(event, context)
% fingerprint_iterator Iterator function
%
% Iterator function that calculates parts of the fingerprint.
%
% Input:
% - event (structure): Event structure.
% - context (structure): Context structure.
%
% Output:
% - context (structure): Modified context structure.
%


    switch (event.type)
        case 'sequence_enter'
            
            files = tracker_evaluate(event.tracker, event.sequence, event.experiment, ...
                'scan', true);

            dates = zeros(1, numel(files));
            
            for j = 1:numel(files)
                stat = dir(files{j});
                dates(j) = stat.datenum;
            end; 
            
            context = [context, dates];
            
    end;

end
