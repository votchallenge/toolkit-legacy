function [document, scores] = report_expected_overlap(context, trackers, sequences, experiments, varargin)
% report_ranking Generate a report based on expected overlap
%
% Performs expected overlap analysis and generates a report based on the results.
%
% Input:
% - context (structure): Report context structure.
% - trackers (cell): An array of tracker structures.
% - sequences (cell): An array of sequence structures.
% - experiments (cell): An array of experiment structures.
% - varargin[UsePractical] (boolean): Use practical difference.
% - varargin[UseLabels] (boolean): Rank according to labels (otherwise rank according to sequences).
% - varargin[HideLegend] (boolean): Hide legend in plots.
% - varargin[RangeThreshold] (double): Threshold used for range estimation.
%
% Output:
% - document (structure): Resulting document structure.
% - scores (matrix): Averaged overlaps for the entire tracker set.
%

uselabels = get_global_variable('report_labels', true);
usepractical = false;
hidelegend = get_global_variable('report_legend_hide', false);
range_threshold = 0.5;

for i = 1:2:length(varargin)
    switch lower(varargin{i}) 
        case 'usepractical'
            usepractical = varargin{i+1};
        case 'uselabels'
            uselabels = varargin{i+1};
        case 'hidelegend'
            hidelegend = varargin{i+1};
        case 'rangethreshold'
            range_threshold = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']);
    end
end 

document = create_document(context, 'expected_overlap', 'title', 'Expected overlap analysis');

results = cell(length(experiments), 1);
scores = nan(length(experiments), length(trackers));

trackers_hash = md5hash(strjoin((cellfun(@(x) x.identifier, trackers, 'UniformOutput', false)), '-'), 'Char', 'hex');
parameters_hash = md5hash(sprintf('%d-%d', uselabels, usepractical));
sequences_hash = md5hash(strjoin((cellfun(@(x) x.name, sequences, 'UniformOutput', false)), '-'), 'Char', 'hex');

for e = 1:length(experiments)

    cache_identifier = sprintf('expected_overlap_%s_%s_%s_%s', experiments{e}.name, ...
        trackers_hash, sequences_hash, parameters_hash);
    
    if uselabels
        labels = cat(2, {'all'}, experiments{e}.labels);
    else
        labels = {'all'};
    end;
    
    result = report_cache(context, cache_identifier, ...
        @analyze_expected_overlap, experiments{e}, trackers, ...
        sequences, 'labels', labels);

    results{e} = result;
  
    [~, peak, low, high] = estimate_evaluation_interval(sequences, range_threshold);
%     
%     for t = 1:numel(trackers)
%         scores(e, t) = mean(results{e}.curves{t});
%     end;
%     
    weights = ones(numel(results{e}.lengths(:)), 1);
    weights(:) = 0;
    weights(low:high) = 1;

    document.section('Experiment %s', experiments{e}.name);
    
    experiment_scores = zeros(numel(trackers), numel(labels));
    experiment_practical = zeros(numel(trackers), numel(labels));

    for p = 1:numel(labels)

        valid =  cellfun(@(x) numel(x) > 0, results{e}.curves, 'UniformOutput', true)';
        
        if p == 1
            plot_title = sprintf('Expected overlap curves for %s', experiments{e}.name);
            plot_id = sprintf('expected_overlap_curves_%s', experiments{e}.name);
        else
            plot_title = sprintf('Expected overlap curves for %s (%s)', experiments{e}.name, labels{p});
            plot_id = sprintf('expected_overlap_curves_%s_%s', experiments{e}.name, labels{p});
            document.subsection('Label %s', labels{p});
        end;
        
        handle = generate_plot('Visible', false, ...
            'Title', plot_title, 'Width', 8);

        hold on;

        plot([peak, peak], [1, 0], '--', 'Color', [0.6, 0.6, 0.6]);
        plot([low, low], [1, 0], ':', 'Color', [0.6, 0.6, 0.6]);
        plot([high, high], [1, 0], ':', 'Color', [0.6, 0.6, 0.6]);

        phandles = zeros(numel(trackers), 1);
        for t = find(valid)
            phandles(t) = plot(results{e}.lengths, results{e}.curves{t}(:, p), 'Color', trackers{t}.style.color);
        end;

        if ~hidelegend
            legend(phandles(valid), cellfun(@(x) x.label, trackers(valid), 'UniformOutput', false), 'Location', 'NorthWestOutside', 'interpreter', 'none'); 
        end;

        xlabel('Sequence length');
        ylabel('Expected overlap');
        xlim([1, max(results{e}.lengths(:))]); 
        ylim([0, 1]);

        hold off;

        document.figure(handle, plot_id, plot_title);

        close(handle);

        plot_title = sprintf('Expected overlap scores for %s', experiments{e}.name);
        plot_id = sprintf('expected_overlaps_%s_%s', experiments{e}.name, labels{p});

        handle = generate_plot('Visible', false, ...
            'Title', plot_title, 'Grid', false);

        hold on;


        experiment_scores(valid, p) = cellfun(@(x) sum(x(~isnan(x(:, p)), p) .* weights(~isnan(x(:, p)))) / sum(weights(~isnan(x(:, p)))), results{e}.curves(valid), 'UniformOutput', true);
        experiment_practical(valid, p) = cellfun(@(x) sum(x(~isnan(x(:, p)), p) .* weights(~isnan(x(:, p)))) / sum(weights(~isnan(x(:, p)))), results{e}.practical(valid), 'UniformOutput', true);

        [ordered_scores, order] = sort(experiment_scores(:, p), 'descend');

        phandles = zeros(numel(trackers), 1);
        for t = 1:numel(order)
            tracker = trackers{order(t)};
            plot([t, t], [0, ordered_scores(t)], ':', 'Color', [0.8, 0.8, 0.8]);
            if experiment_practical(t) > 0.001 && usepractical
                draw_interval(t, ordered_scores(t), experiment_practical(t), experiment_practical(t), 'Color', [0.6, 0.6, 0.6]);            
            end
            phandles(t) = plot(t, ordered_scores(t), tracker.style.symbol, 'Color', tracker.style.color, 'MarkerSize', 10, 'LineWidth', tracker.style.width);
        end;

        if ~hidelegend
            legend(phandles, cellfun(@(x) x.label, trackers(order), 'UniformOutput', false), 'Location', 'NorthWestOutside', 'interpreter', 'none'); 
        end;

        xlabel('Order');
        ylabel('Average expected overlap');
        xlim([0.9, numel(trackers) + 0.1]); 
        set(gca, 'XTick', 1:max(1, ceil(log(numel(trackers)))):numel(trackers));
        set(gca, 'XDir', 'Reverse');
        ylim([0, 1]);

        hold off;

        document.figure(handle, plot_id, plot_title);

        close(handle);
    end;

    document.subsection('Overview');
    document.text('Scores calculated as an average over interval %d to %d', low, high);

    if uselabels && numel(labels) > 1
    
        h = generate_ordering_plot(trackers, experiment_scores(:, 2:end)' , labels(2:end), ...
            'flip', false, 'legend', ~hidelegend, 'scope', [0, 1]);
            document.figure(h, sprintf('ordering_expected_overlap_%s', experiments{e}.name), ...
            'Ordering plot for expected overlap');

        close(h);
        
    end
    
    scores(e, valid) = experiment_scores(valid, 1)';


    experiments_hash = md5hash(strjoin(sort(cellfun(@(x) x.name, experiments, 'UniformOutput', false)), '-'), 'Char', 'hex');
    sequences_hash = md5hash(strjoin(sort(cellfun(@(x) x.name, sequences, 'UniformOutput', false)), '-'), 'Char', 'hex');
    trackers_hash = md5hash(strjoin(sort(cellfun(@(x) x.identifier, trackers, 'UniformOutput', false)), '-'), 'Char', 'hex');

    cache_identifier = sprintf('speed_%s_%s_%s.mat', experiments_hash, trackers_hash, sequences_hash);

    speed = report_cache(context, cache_identifier, @analyze_speed, experiments, trackers, sequences, 'cache', context.cachedir);

    averaged_normalized = squeeze(mean(mean(speed.normalized, 3), 1));

    plot_title = sprintf('Expected overlap scores vs. speed for %s', experiments{e}.name);
    plot_id = sprintf('expected_overlaps_speed_%s', experiments{e}.name);

    handle = generate_plot('Visible', false, ...
        'Title', plot_title, 'Grid', false);

    hold on;

    % In order to keep results in perspective we draw the speed in
    % logarithmic scale. The middle line is fitted to point where EFO = 20
    % (approximated real-time threshold).

    real_time_threshold = 20;

    speed_scaling_constant = -log(0.5) * real_time_threshold;
    plot([real_time_threshold, real_time_threshold], [1, 0], '--', 'Color', [0.6, 0.6, 0.6]);

    phandles = zeros(numel(trackers), 1);
    for t = 1:numel(trackers)
        tracker = trackers{t};

%         phandles(t) = plot(exp(-speed_scaling_constant / averaged_normalized(t)), ...
%             experiment_scores(t), tracker.style.symbol, ...
%             'Color', tracker.style.color, 'MarkerSize', 10, 'LineWidth', tracker.style.width);
        phandles(t) = plot(averaged_normalized(t), ...
            experiment_scores(t), tracker.style.symbol, ...
            'Color', tracker.style.color, 'MarkerSize', 10, 'LineWidth', tracker.style.width);

    end;

    if ~hidelegend
        legend(phandles, cellfun(@(x) x.label, trackers, 'UniformOutput', false), 'Location', 'NorthWestOutside', 'interpreter', 'none'); 
    end;

    xlabel('Normalized speed (EFO)');
    ylabel('Average expected overlap');

    ylim([0, 1]);
    set(gca, 'XScale', 'log');
    xlim([0, ceil(max(averaged_normalized) / 100) * 100]);
    %speed_ticks = real_time_threshold * 3.^(-2:2);
    %set(gca, 'XTick', exp(-speed_scaling_constant ./ speed_ticks));
    %set(gca, 'XTickLabel', cellfun(@(x) sprintf('%.0f', x), num2cell(speed_ticks), 'UniformOutput', false));

    hold off;

    document.figure(handle, plot_id, plot_title);

    close(handle);
       
end;

document.write();

end

function [gmm, peak, low, high] = estimate_evaluation_interval(sequences, threshold)

sequence_lengths = cellfun(@(x) x.length, sequences, 'UniformOutput', true);
model = gmm_estimate(sequence_lengths); % estimate the pdf by KDE
 
% tabulate the GMM from zero to max length
x = 1:max(sequence_lengths) ;
p = gmm_evaluate(model, x) ;
p = p / sum(p); 
gmm.x = x;
gmm.p = p;

[low, high] = find_range(p, threshold) ;
[~, peak] = max(p);

end

function draw_interval(x, y, low, high, varargin) 
    plot([x - 0.1, x + 0.1], [y, y] - low, varargin{:});
    plot([x - 0.1, x + 0.1], [y, y] + high, varargin{:});
    plot([x, x], [y - low, y + high], varargin{:});
end

function [low, high] = find_range(p, density)

% find maximum on the KDE
[~, x_max] = max(p);
low = x_max ;
high = x_max ;

for i = 0:length(p)
    x_lo_tmp = low - 1 ;
    x_hi_tmp = high + 1 ;
    
    sw_lo = 0 ; sw_hi = 0 ; % boundary indicator
    % clip
    if x_lo_tmp <= 0 , x_lo_tmp = 1 ;  sw_lo = 1 ; end
    if x_hi_tmp >= length(p), x_hi_tmp = length(p); sw_hi = 1; end
    
    % increase left or right boundary
    if sw_lo==1 && sw_hi==1
        low = x_lo_tmp ;
        high = x_hi_tmp ;
        break ;
    elseif sw_lo==0 && sw_hi==0
        if p(x_lo_tmp) > p(x_hi_tmp)
            low = x_lo_tmp ;
        else
            high = x_hi_tmp ;
        end
    else
        if sw_lo==0, low = x_lo_tmp ; else high = x_hi_tmp ; end
    end
    
    % check the integral under the range
    s_p = sum(p(low:high)) ;
    if s_p >= density
        return ;
    end
end            

end
