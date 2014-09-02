function [index_file] = ar_analysis(context, trackers, sequences, experiments, varargin)

index_file = sprintf('%sarplots.html', context.prefix);
temporary_index_file = tempname;
template_file = fullfile(get_global_variable('toolkit_path'), 'templates', 'report.html');

index_fid = fopen(temporary_index_file, 'w');
latex_fid = [];
sensitivity = 30;

labels = {};

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'latexfile'
            latex_fid = varargin{i+1};
        case 'reporttemplate'
            template_file = varargin{i+1};
        case 'labels'
            labels = varargin{i+1} ;
        case 'index'
            index_file = varargin{i+1} ;
        case 'sensitivity'
            sensitivity = varargin{i+1} ;            
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
    
	if isempty(labels)

		aspects = create_sequence_aspects(experiment, trackers, experiment_sequences);
		
	else
		
		aspects = create_label_aspects(experiment, trackers, experiment_sequences, labels);

	end;

    accuracy = nan(numel(aspects), numel(trackers));
    robustness = nan(numel(aspects), numel(trackers));

    repeat = get_global_variable('repeat', 1);
    
    for s = 1:length(aspects)

        print_indent(1);

        print_text('Processing aspect %s ...', aspects{s}.name);
   
        for t = 1:length(trackers)

            print_indent(1);

	        [A, R] = aspects{s}.aggregate(experiment, trackers{t}, experiment_sequences);

	        valid_frames = ~isnan(A) ;

	        accuracy(s, t) = mean(A(valid_frames));
            
            R = sum(reshape(R, repeat, length(R) / repeat), 2);
            
	        robustness(s, t) = mean(R);

            print_indent(-1);

        end;

		robustness(s, :) = robustness(s, :) ./ aspects{s}.length(experiment_sequences);

        hf = generate_ar_plot(trackers, accuracy(s, :), robustness(s, :), 'sensitivity', sensitivity);
        
        insert_figure(context, index_fid, hf, sprintf('arplot_%s_%s', ...
            experiment.name, aspects{s}.name), ...
            sprintf('Aspect %s', aspects{s}.name));
    
        print_indent(-1);

    end;

    hf = generate_ar_plot(trackers, mean(accuracy), mean(robustness), 'sensitivity', sensitivity);

    insert_figure(context, index_fid, hf, sprintf('arplot_%s', ...
        experiment.name), ...
        sprintf('Experiment %s', experiment.name));

    print_indent(-1);

    print_text('Writing report ...');

end;

fclose(index_fid);

generate_from_template(fullfile(context.root, index_file), template_file, ...
    'body', fileread(temporary_index_file), 'title', 'A-R analysis report', ...
    'timestamp', datestr(now, 31));

delete(temporary_index_file);


