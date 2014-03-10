function [index_file] = failure_analysis(directory, trackers, sequences, experiments, labels, varargin)

repeat = get_global_variable('repeat', 1);

temporary_dir = tempdir;

index_file = fullfile(directory, 'failures.html');
temporary_index_file = fullfile(temporary_dir, 'index.tmp');
template_file = fullfile(fileparts(mfilename('fullpath')), 'report.html');

tracker_labels = cellfun(@(x) x.identifier, trackers, 'UniformOutput', 0);
latex_fid = [];

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


index_fid = fopen(temporary_index_file, 'w');

image_directory = fullfile(directory, 'images');

mkpath(image_directory);

for e = 1:numel(experiments)

    experiment = experiments{e};

    print_text('Failure analysis for experiment %s ...', experiment.name);

    print_indent(1);

    print_text('Loading data ...');

    fprintf(index_fid, '<h2>Experiment %s</h2>\n', experiment.name);

    experiment_sequences = convert_sequences(sequences, experiment.converter);
            
    for s = 1:length(experiment_sequences)

        print_indent(1);

        failure_histogram = zeros(numel(trackers), experiment_sequences{s}.length);
        
        print_text('Processing sequence %s ...', experiment_sequences{s}.name);

        for t = 1:length(trackers)

            print_indent(1);

            result_directory = fullfile(trackers{t}.directory, experiment.name, experiment_sequences{s}.name);
            
            for j = 1:repeat

                result_file = fullfile(result_directory, sprintf('%s_%03d.txt', experiment_sequences{s}.name, j));
                trajectory = load_trajectory(result_file);

                if isempty(trajectory)
                    continue;
                end;

                if length(trajectory) < experiment_sequences{s}.length
                    trajectory(end+1:experiment_sequences{s}.length, :) = NaN;
                end;
                
                failure_histogram(t, :) = failure_histogram(t, :) + (trajectory(:, 4) == -2)';
                
                
            end;

            print_indent(-1);

        end;

        hf = figure('Visible', 'off');
        imagesc(failure_histogram);
        set(gca,'ytick',(1:numel(trackers)),'yticklabel', tracker_labels);
        title(sprintf('Sequence %s, individual trackers', experiment_sequences{s}.name));
        print( hf, '-dpng', '-r130', fullfile(image_directory, sprintf('failures_%s_%s_individual.png', experiment.name, experiment_sequences{s}.name)));
        
        hf = figure('Visible', 'off');

        labels = experiment_sequences{s}.labels.data;
        labelsplit = mat2cell(labels, size(labels, 1), ones(1, size(labels, 2)));
        starts = cellfun(@(x) find(diff([0; x; 0]) > 0), labelsplit, 'UniformOutput', 0);
        ends = cellfun(@(x) find(diff([0; x; 0]) < 0), labelsplit, 'UniformOutput', 0);

        hold on;
        timeline(experiment_sequences{s}.labels.names, starts, ends);
        combined_histogram = sum(failure_histogram, 1);
        combined_histogram = (combined_histogram / max(combined_histogram)) * numel(experiment_sequences{s}.labels.names);
        plot(combined_histogram);
        set(gca, 'XLim', [1, experiment_sequences{s}.length]);
        hold off;
        title(sprintf('Sequence %s, combined failures with properties', experiment_sequences{s}.name));
        print( hf, '-dpng', '-r130', fullfile(image_directory, sprintf('failures_%s_%s_combined.png', experiment.name, experiment_sequences{s}.name)));        
        
        fprintf(index_fid, '<h3>Sequence %s</h3>\n', experiment_sequences{s}.name);
        
        fprintf(index_fid, '<p><img src="images/failures_%s_%s_individual.png" alt="%s" /><img src="images/failures_%s_%s_combined.png" alt="%s" /></p>\n', ...
            experiment.name, experiment_sequences{s}.name, experiment_sequences{s}.name, experiment.name, experiment_sequences{s}.name, experiment_sequences{s}.name);
        
        print_indent(-1);

    end;


    print_indent(-1);

    print_text('Writing report ...');

end;

fclose(index_fid);

generate_from_template(index_file, template_file, ...
    'body', fileread(temporary_index_file), 'title', 'Failure analysis report', ...
    'timestamp', datestr(now, 31));


