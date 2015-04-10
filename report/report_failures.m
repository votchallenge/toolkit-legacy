function [document] = report_failures(context, trackers, sequences, experiments, varargin)

document = create_document(context, 'failures', 'title', 'Failure overview');

for i = 1:2:length(varargin)
    switch lower(varargin{i})         
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end

tracker_labels = cellfun(@(x) iff(isfield(x.metadata, 'verified') && x.metadata.verified, [x.label, '*'], x.label), trackers, 'UniformOutput', 0);

for e = 1:numel(experiments)

    experiment = experiments{e};

    histograms = analyze_failures(experiment, trackers, sequences, 'cache', context.cachedir);

    document.subsection('Experiment %s', experiment.name);

    experiment_sequences = convert_sequences(sequences, experiment.converter);
            
    for s = 1:length(experiment_sequences)

        document.subsection('Sequence %s',  experiment_sequences{s}.name);
        
        document.raw('<div class="imagegrid">\n');
        
        hf = figure('Visible', 'off');
        imagesc(histograms{s});
        set(gca,'ytick',(1:numel(trackers)),'yticklabel', tracker_labels);
        
        document.figure(hf, sprintf('failures_%s_%s_individual', experiment.name, experiment_sequences{s}.name), ...
            sprintf('Sequence %s, individual trackers', experiment_sequences{s}.name));
        
        hf = figure('Visible', 'off');
        labels = experiment_sequences{s}.labels.data;
        labelsplit = mat2cell(labels, size(labels, 1), ones(1, size(labels, 2)));
        starts = cellfun(@(x) find(diff([0; x; 0]) > 0), labelsplit, 'UniformOutput', 0);
        ends = cellfun(@(x) find(diff([0; x; 0]) < 0), labelsplit, 'UniformOutput', 0);

        hold on;
        timeline(experiment_sequences{s}.labels.names, starts, ends);
        combined_histogram = sum(histograms{s}, 1);
        combined_histogram = (combined_histogram / max(combined_histogram)) * numel(experiment_sequences{s}.labels.names);
        plot(combined_histogram);
        set(gca, 'XLim', [1, experiment_sequences{s}.length]);
        hold off;

        document.figure(hf, sprintf('failures_%s_%s_combined', experiment.name, experiment_sequences{s}.name), ...
            sprintf('Sequence %s, combined failures with properties', experiment_sequences{s}.name));
        
        document.raw('</div>\n');
    end;

end;

document.write();

