function [index_file] = ar_analysis(context, trackers, sequences, experiments, varargin)

repeat = get_global_variable('repeat', 1);
burnin = get_global_variable('burnin', 0);

index_file = sprintf('%sarplots.html', context.prefix);
temporary_index_file = tempname;
template_file = fullfile(fileparts(mfilename('fullpath')), 'report.html');

index_fid = fopen(temporary_index_file, 'w');
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

        accuracy = nan(repeat, length(trackers));
        failures = nan(repeat, length(trackers));
                
        for t = 1:length(trackers)

            print_indent(1);

            result_directory = fullfile(trackers{t}.directory, experiment.name, experiment_sequences{s}.name);
            
            for j = 1:repeat

                result_file = fullfile(result_directory, sprintf('%s_%03d.txt', experiment_sequences{s}.name, j));
                trajectory = load_trajectory(result_file);

                if isempty(trajectory)
                    continue;
                end;

                accuracy(j, t) = estimate_accuracy(trajectory, experiment_sequences{s}, 'burnin', burnin);

                failures(j, t) = estimate_failures(trajectory, experiment_sequences{s});

            end;

            failures(isnan(failures(:, t)), t) = mean(failures(~isnan(failures(:, t)), t));
            accuracy(isnan(accuracy(:, t)), t) = mean(accuracy(~isnan(accuracy(:, t)), t));
            
            print_indent(-1);

        end;

        hf = generate_ar_plot(trackers, accuracy, failures);
        
        insert_figure(context, index_fid, hf, sprintf('arplot_%s_%s.png', ...
            experiment.name, experiment_sequences{s}.name), ...
            sprintf('Sequence %s', experiment_sequences{s}.name));
    
        print_indent(-1);

    end;


    print_indent(-1);

    print_text('Writing report ...');

end;

fclose(index_fid);

generate_from_template(fullfile(context.root, index_file), template_file, ...
    'body', fileread(temporary_index_file), 'title', 'A-R analysis report', ...
    'timestamp', datestr(now, 31));

delete(temporary_index_file);


function hf = generate_ar_plot(trackers, accuracy, failures, varargin)

    plot_title = [];
    sensitivity = 30;
    
    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'title'
                plot_title = varargin{i+1};
            case 'sensitivity'
                sensitivity = varargin{i+1};                 
            otherwise 
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end 

    hf = figure('Visible', 'off');

    hold on;
    grid on;
    
    if ~isempty(plot_title)
        title(plot_title, 'interpreter', 'none'); 
    end;
    available = true(length(trackers), 1);

    for t = 1:length(trackers)

        if all(isnan(accuracy(:, t)))
            available(t) = 0;
            continue;
        end;

        ar_mean = mean([accuracy(:, t), failures(:, t)]);

        plot(exp(-ar_mean(2) / sensitivity), ar_mean(1), ...
            trackers{t}.style.symbol, 'Color', trackers{t}.style.color, ...
            'MarkerSize', 10, 'LineWidth', trackers{t}.style.width);

    end;
    
    tracker_labels = cellfun(@(x) x.label, trackers, 'UniformOutput', 0);

    legend(tracker_labels(available), 'Location', 'NorthWestOutside'); 
    xlabel(sprintf('Reliability (S = %d)', sensitivity));
    ylabel('Accuracy');
    xlim([0, 1]); 
    ylim([0, 1]);
    hold off;
