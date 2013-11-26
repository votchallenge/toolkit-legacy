function [index_file] = ar_analysis(directory, trackers, sequences, experiments, varargin)

global track_properties;

temporary_dir = tempdir;

index_file = fullfile(directory, 'arplot.html');
temporary_index_file = fullfile(temporary_dir, 'index.tmp');
template_file = fullfile(fileparts(mfilename('fullpath')), 'report.html');

tracker_labels = cellfun(@(x) x.identifier, trackers, 'UniformOutput', 0);

index_fid = fopen(temporary_index_file, 'w');
latex_fid = [];

image_directory = fullfile(directory, 'images');

mkpath(image_directory);

sensitivity = 50;

lines = hsv(length(trackers));
lines = lines(randperm(length(lines)), :);
dashes = {'o', 'x', '*', 'v', 'd', '+', '<', 'p', '>'};

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'latexfile'
            latex_fid = varargin{i+1};
        case 'reporttemplate'
            template_file = varargin{i+1};  
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

for e = 1:numel(experiments)

    experiment = experiments{e};

    print_text('A-R plot analysis for experiment %s ...', experiment.name);

    print_indent(1);

    print_text('Loading data ...');

    fprintf(index_fid, '<h2>Experiment %s</h2>\n', experiment.name);
    
    experiment_sequences = convert_sequences(sequences, experiment.converter);
    
    for s = 1:length(experiment_sequences)

        print_indent(1);

        print_text('Processing sequence %s ...', experiment_sequences{s}.name);

        accuracy = nan(track_properties.repeat, length(trackers));
        failures = nan(track_properties.repeat, length(trackers));
                
        for t = 1:length(trackers)

            print_indent(1);

            result_directory = fullfile(trackers{t}.directory, experiment.name, experiment_sequences{s}.name);
            
            for j = 1:track_properties.repeat

                result_file = fullfile(result_directory, sprintf('%s_%03d.txt', experiment_sequences{s}.name, j));
                trajectory = load_trajectory(result_file);

                if isempty(trajectory)
                    continue;
                end;

                accuracy(j, t) = estimate_accuracy(trajectory, experiment_sequences{s}, 'burnin', track_properties.burnin);

                failures(j, t) = estimate_failures(trajectory, experiment_sequences{s});

            end;

            failures(isnan(failures(:, t)), t) = mean(failures(~isnan(failures(:, t)), t));
            accuracy(isnan(accuracy(:, t)), t) = mean(accuracy(~isnan(accuracy(:, t)), t));
            
            print_indent(-1);

        end;

        hf = figure('Visible', 'off');

        hold on;
        grid on;
        title(sprintf('Sequence %s', experiment_sequences{s}.name), 'interpreter', 'none'); 

        available = true(length(trackers), 1);
        
        for t = 1:length(trackers)

            if all(isnan(accuracy(:, t)))
                available(t) = 0;
                continue;
            end;
            
            ar_mean = mean([accuracy(:, t), failures(:, t)]);

        	plot(exp(-ar_mean(2) / sensitivity), ar_mean(1), dashes{mod(t, length(dashes))+1}, 'Color', lines(t, :),'MarkerSize',10,  'LineWidth', mod(t+1, 2) + 1);
    
        end;
        legend(tracker_labels(available), 'Location', 'NorthWestOutside'); 
        xlabel(sprintf('Reliability (S = %d)', sensitivity));
        ylabel('Accuracy');
        xlim([0, 1]); 
        ylim([0, 1]);
        hold off;
        
        print( hf, '-dpng', '-r130', fullfile(image_directory, sprintf('arplot_%s_%s.png', experiment.name, experiment_sequences{s}.name)));
        
        fprintf(index_fid, '<h3>Sequence %s</h3>\n', experiment_sequences{s}.name);
        
        fprintf(index_fid, '<p><img src="images/arplot_%s_%s.png" alt="%s" /></p>\n', ...
            experiment.name, experiment_sequences{s}.name, experiment_sequences{s}.name);
        
        print_indent(-1);

    end;


    print_indent(-1);

    print_text('Writing report ...');

end;

fclose(index_fid);

generate_from_template(index_file, template_file, ...
    'body', fileread(temporary_index_file), 'title', 'A-R analysis report', ...
    'timestamp', datestr(now, 31));
