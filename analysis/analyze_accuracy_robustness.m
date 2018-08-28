function [result] = analyze_accuracy_robustness(experiment, trackers, sequences, varargin)
% analyze_accuracy_robustness Performs ranking analysis
%
% Performs ranking analysis for a given experiment on a set trackers and sequences.
%
% Input:
% - experiment (structure): A valid experiment structures.
% - trackers (cell): A cell array of valid tracker descriptor structures.
% - sequences (cell): A cell array of valid sequence descriptor structures.
% - varargin[Ranking] (boolean): Perform ranking analysis, used by default.
% - varargin[Tags] (cell): An array of tag names that should be used
% instead of sequences.
% - varargin[UsePractical] (boolean): Use practical difference for accuracy.
% - varargin[Alpha] (double): Statistical significance parameter.
% - varargin[Adaptation] (string): Type of rank adaptation. See
% adapter_ranks for more details.
%
% Output:
% - result (structure): A structure with the following fields
%     - accuracy
%          - values: average overlap matrix
%          - ranks: accuracy ranks matrix (if applicable)
%     - robustness
%          - values: number of failures matrix
%          - normalized: number of failures matrix (normalized)
%          - ranks: robustness ranks matrix (if applicable)
%     - lengths: number of frames for individual selectors
%     - tags: names of individual selectors

    usepractical = false;
    ranking = true;
    tags = {};
	adaptation = 'mean';
    alpha = 0.05;

    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'ranking'
                ranking = varargin{i+1} ;
            case 'tags'
                tags = varargin{i+1} ;
            case 'usepractical'
                usepractical = varargin{i+1} ;
            case 'alpha'
                alpha = varargin{i+1};
            case 'adaptation'
                adaptation = varargin{i+1};
            otherwise
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end

    print_text('Ranking analysis for experiment %s ...', experiment.name);

    if ~any(strcmp(experiment.type, {'supervised', 'realtime'}))
        error('Ranking analysis can only be used in supervised experiment scenario.');
    end;

    if experiment.parameters.repetitions < 5 && ranking
        error('The experiment specifies less than 5 repetitions. Not valid for statistical consideration.');
    end

    if experiment.parameters.repetitions < 15 && ranking
        print_text('Warning: the experiment specifies less than 15 repetitions, the results may be statistically unstable.');
    end;

    print_indent(1);

    experiment_sequences = convert_sequences(sequences, experiment.converter);

    if ~isempty(tags)

        tags = unique(tags); % Remove any potential duplicates.

        selectors = sequence_tag_selectors(experiment, ...
            experiment_sequences, tags);

    else

        selectors = sequence_selectors(experiment, experiment_sequences);

    end;

    if ~ranking
        % Disable ranking
        alpha = -1;
    end;
    
    [accuracy, robustness, lengths] = trackers_ar(experiment, trackers, ...
        experiment_sequences, selectors, alpha, usepractical, adaptation);

    result = struct('accuracy', accuracy, 'robustness', robustness, 'lengths', lengths);
    result.tags = cellfun(@(x) x.name, selectors, 'UniformOutput', false);

    print_indent(-1);

end

function [accuracy, robustness, lengths] = trackers_ar(experiment, trackers, ...
    sequences, selectors, alpha, usepractical, adaptation)

    N_trackers = length(trackers) ;
    N_selectors = length(selectors) ;

    accuracy.values = zeros(N_selectors, N_trackers);
    robustness.values = zeros(N_selectors, N_trackers);
    robustness.normalized = zeros(N_selectors, N_trackers);
    
    if alpha > 0
        accuracy.ranks = zeros(N_selectors, N_trackers);
        robustness.ranks = zeros(N_selectors, N_trackers);
    end;

    lengths = zeros(N_selectors, 1);

    for a = 1:length(selectors)

	    print_indent(1);

	    print_text('Processing selector %s ...', selectors{a}.name);

        % rank trackers and calculate statistical significance of differences
        [average_overlap, average_failures, average_failurerate, HA, HR, available] = ...
            trackers_raw_scores_selector(experiment, trackers, sequences, selectors{a}, alpha, usepractical);

        accuracy.values(a, :) = average_overlap;
        robustness.values(a, :) = average_failures;
        robustness.normalized(a, :) = average_failurerate;
        
        if alpha > 0
        
            [~, order_by_accuracy] = sort(average_overlap(available), 'descend');
            accuracy_ranks = ones(size(available)) * length(available);
            [~, accuracy_ranks(available)] = sort(order_by_accuracy, 'ascend') ;

            [~, order_by_robustness] = sort(average_failures(available), 'ascend');
            robustness_ranks = ones(size(available)) * length(available);
            [~, robustness_ranks(available)] = sort(order_by_robustness,'ascend');

            % get adapted ranks
            adapted_accuracy_ranks = adapted_ranks(accuracy_ranks, HA, adaptation);
            adapted_robustness_ranks = adapted_ranks(robustness_ranks, HR, adaptation);

            % mask out results that are not available
            adapted_accuracy_ranks(~available) = nan;
            adapted_robustness_ranks(~available) = nan;
            accuracy.ranks(a, :) = adapted_accuracy_ranks;
            robustness.ranks(a, :) = adapted_robustness_ranks;

        end;
            
        lengths(a) = selectors{a}.length(sequences);

	    print_indent(-1);

    end

end

function [average_accuracy, average_failures, average_failurerate, HA, HR, available] ...
    = trackers_raw_scores_selector(experiment, trackers, sequences, selector, alpha, usepractical)

    cacheA = cell(length(trackers), 1);
    cacheR = cell(length(trackers), 1);

    HA = false(length(trackers)); % results of statistical testing
    HR = false(length(trackers)); % results of statistical testing

    average_accuracy = nan(length(trackers), 1);
    average_failures = nan(length(trackers), 1);
    average_failurerate = nan(length(trackers), 1);

    available = true(length(trackers), 1);

    if alpha > 0 && usepractical
        practical = selector.groundtruth_values(sequences, 'practical');
        practical = cat(1, practical{:});
    else
        practical = [];
    end

	print_indent(1);
    [~, lengths] = selector.length(sequences);

    for t1 = 1:length(trackers)

		print_text('Processing tracker %s ...', trackers{t1}.identifier);

        if isempty(cacheA{t1})
            [O1, F1] = calculate_accuracy_overlap(selector, experiment, trackers{t1}, sequences);
            cacheA{t1} = O1; cacheR{t1} = F1;
        else
            O1 = cacheA{t1}; F1 = cacheR{t1};
        end;

        if isempty(O1)
            available(t1) = false;
			HA(t1, :) = true; HA(:, t1) = true;
			HR(t1, :) = true; HR(:, t1) = true;
            HA(t1, t1) = false; HR(t1, t1) = false;
            continue;
        end

        valid_frames = ~isnan(O1) ;

        % O1 ... stacked per-frame overlaps (already averaged over
        % repeats).
        %
        % F1 ... fragments (rows) x repeats (columns) of raw failure count.

        % Average accuracy is average over valid frames (non NaN).
        if all(valid_frames == 0)
            average_accuracy(t1) = 0;
        else
            average_accuracy(t1) = mean(O1(valid_frames));
        end;

        % Average failures are sum of failures in fragments averaged over
        % repetitions
        average_failures(t1) = mean(sum(F1, 1));

        % Average failure rate is sum of failures in fragments divided by
        % total length of selector, averaged over repetitions
        average_failurerate(t1) = mean(sum(F1, 1) ./ sum(lengths));

        if alpha > 0
        
            for t2 = t1+1:length(trackers)

                t2
                
                if isempty(cacheA{t1})
                    [O1, F1] = calculate_accuracy_overlap(selector, experiment, trackers{t1}, sequences);
                    cacheA{t1} = O1; cacheR{t1} = F1;
                else
                    O1 = cacheA{t1}; F1 = cacheR{t1};
                end;

                if isempty(cacheA{t2})
                    [O2, F2] = calculate_accuracy_overlap(selector, experiment, trackers{t2}, sequences);
                    cacheA{t2} = O2; cacheR{t2} = F2;
                else
                    O2 = cacheA{t2}; F2 = cacheR{t2};
                end;

                if isempty(O2)
                    available(t2) = false;
                    continue;
                end

                % If alpha is 0 then we disable the equivalence testing
                if alpha == 0

                    ha = true; hr = true;

                else

                    [ha, hr] = test_significance(O1, F1, O2, F2, alpha, practical);

                end;

                HA(t1, t2) = ha; HA(t2, t1) = HA(t1, t2);
                HR(t1, t2) = hr; HR(t2, t1) = HR(t1, t2);
            end;
        end;
    end;

	print_indent(-1);

    average_accuracy(isnan(average_accuracy)) = 0;


end

function [aggregated_overlap, aggregated_failures] = calculate_accuracy_overlap(selector, experiment, tracker, sequences)

    aggregated_overlap = [];
    aggregated_failures = [];
    
    burnin = experiment.parameters.burnin;
    
    groundtruth = selector.groundtruth(sequences);
    trajectories = selector.results(experiment, tracker, sequences);
    
    repeat = experiment.parameters.repetitions;
    
    for s = 1:numel(groundtruth)
    
        accuracy = nan(repeat, length(groundtruth{s}));
        failures = nan(repeat, 1);
        
        for r = 1:size(trajectories, 2)
        
            if isempty(trajectories{s, r})
                continue;
            end;
            
            [~, frames] = estimate_accuracy(trajectories{s, r}, groundtruth{s}, 'burnin', burnin, 'BindWithin', [sequences{s}.width, sequences{s}.height]);

            accuracy(r, :) = frames;

            failures(r) = estimate_failures(trajectories{s, r}, groundtruth{s});

        end;
        
        frames = num2cell(accuracy, 1);
        sequence_overlaps = cellfun(@(frame) nanmean(frame), frames);

        failures(isnan(failures)) = nanmean(failures);
        sequence_failures = failures';

        if ~isempty(sequence_overlaps)
            aggregated_overlap = [aggregated_overlap, sequence_overlaps]; %#ok<AGROW>
        end;

        if ~isempty(sequence_failures)
            aggregated_failures = [aggregated_failures; sequence_failures]; %#ok<AGROW>
        end;
        
    end;
    
    aggregated_failures = aggregated_failures(~isnan(aggregated_failures(:, 1)), :);
    
end

function [ha, hr, hp] = test_significance(A1, R1, A2, R2, alpha, practical)
% test_significance Verify difference of A-R performance for two trackers
%
% Compare A-R performance of two trackers taking into account statistical
% and practical difference of results.
%
% Input:
% - A1 (double matrix): Per-frame accuracy for first tracker
% - R1 (double matrix): Per-segment robustness for first tracker
% - A2 (double matrix): Per-frame accuracy for second tracker
% - R2 (double matrix): Per-segment robustness for second tracker
% - alpha (double): Confidence parameter
% - practical (boolean): Take into account practical difference for the
% frames
%
% Output:
% - ha (boolean): Is accuracy different
% - hr (boolean): Is robustness different
% - hp (number): Number of frames for which the practical difference test
% was positive
%

    % Testing accuracy significance

    % Statistical test
    dif = A1 - A2;
    valid = ~isnan(dif);
    dif = dif(valid) ;
    if (length(dif) < 25)
        print_text('Warning: less than 25 samples when comparing trackers. Cannot reject hypothesis');
        ha = 1;
    else
        if (is_octave)
            try
            pa = wilcoxon_test(A1(valid), A2(valid));
            ha = (pa <= alpha);
            catch
                %A1(valid) - A2(valid)
                %pa = 0;
                ha = 1;
            end;
        else
            [~, ha, ~] = signrank(dif, [], 'alpha', alpha ) ;
        end;
    end;

    hp = 0;

    % Practical difference of accuracy
    if ~isempty(practical)
        hp = sum(dif' < practical(valid));
        if abs(mean(dif' ./ practical(valid))) < 1
            ha = 0;
        end;

    end;

    % Testing robustness significance
    R1 = R1(:);
    R2 = R2(:);
	%R1 = mean(R1,2);
    %R2 = mean(R2,2);


    if (is_octave)
       pr = u_test(R1, R2);
       hr = (pr <= alpha);
    else
       [~, hr] = ranksum(R1, R2, 'alpha', alpha) ;
    end;

end
