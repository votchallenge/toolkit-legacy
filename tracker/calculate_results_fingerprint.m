function hash = calculate_results_fingerprint(tracker, experiment, sequences)

time_string = iterate(experiment, tracker, sequences, 'iterator', @fingerprint_iterator, 'context', []);

hash = md5hash(time_string);

end

function context = fingerprint_iterator(event, context)

    switch (event.type)
        case 'sequence_enter'
            
            directory = fullfile(event.tracker.directory, event.experiment.name);

            dates = zeros(1, event.experiment.parameters.repetitions);
            
            for j = 1:event.experiment.parameters.repetitions

                result_file = fullfile(directory, event.sequence.name, sprintf('%s_%03d.txt', event.sequence.name, j));

                if exist(result_file, 'file')
                   
                    stat = dir(result_file);
                    
                    dates(j) = stat.datenum;
                    
                end

            end; 
            
            context = [context, dates];
            
    end;

end