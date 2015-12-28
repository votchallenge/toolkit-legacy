function [performance_accumulated] = validate_clusters(experiments, sequences, trackers, clusters_ap, clusters_kmeans)

    performance_score = zeros(length(sequences), size(trackers,1)*2); 

    for t = 1:size(trackers, 1)
        score = calculate_scores(trackers{t}, sequences, [trackers{t}.directory '/' experiments{1}.name]);  

        for i = 1:size(score, 1)
            acc = 9 - floor(score(i,1)*10);
            reinit = min([floor(score(i,2)) 9]);
            performance_score(i, (2*(t-1)+1):(2*t)) = [reinit acc];
        end
    end

    performance_accumulated = [sum(performance_score(:,1:2:end), 2) sum(performance_score(:,2:2:end), 2)]/size(trackers, 1);

    c_ap_vars = zeros(length(clusters_ap.clusters_id),2);
    c_kmeans_vars = zeros(length(clusters_kmeans.clusters_id),2);

    for i = 1:length(clusters_ap.clusters_id)
        c_ap_vars(i,:) = var(performance_accumulated(clusters_ap.clusters_id{i},:));
    end
    for i = 1:length(clusters_kmeans.clusters_id)
        c_kmeans_vars(i,:) = var(performance_accumulated(clusters_kmeans.clusters_id{i},:));
    end

    fprintf('Affine propagation clustering - inner cluster perf. variation (robustness/accuracy) : %.02f/%.02f\n', mean(c_ap_vars, 1));
    fprintf('K-means clustering            - inner cluster perf. variation (robustness/accuracy) : %.02f/%.02f\n', mean(c_kmeans_vars, 1));
end

function [scores] = calculate_scores(tracker, sequences, result_directory)

    if ~isfield(tracker, 'performance')
        tracker.performance = readstruct(benchmark_hardware(tracker));
    end;

    scores = nan(length(sequences), 2);
    repeat = get_global_variable('repeat', 1);
    burnin = get_global_variable('burnin', 0);

    for i = 1:length(sequences)

        directory = fullfile(result_directory, sequences{i}.name);

        result_file = fullfile(directory, sprintf('%s_%03d.txt', sequences{i}.name, 1));
        try 
            trajectory = read_trajectory(result_file);
        catch
            continue;
        end;
        
        accuracy = estimate_accuracy(trajectory, sequences{i}, 'burnin', burnin);
        reliability = estimate_failures(trajectory, sequences{i});
        scores(i, :) = [accuracy reliability];

    end;
end

