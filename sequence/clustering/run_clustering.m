%% set environment variables (sequence dir, result output dir, ...)
config.result_base_dir = './clustering_results';

config.result_directory = [ config.result_base_dir '/attributes/'];
config.result_directory_clusters_img = [ config.result_base_dir '/clusters_imgages/'];
if ~exist(config.result_base_dir, 'dir') mkdir(config.result_base_dir); end;
if ~exist(config.result_directory, 'dir') mkdir(config.result_directory); end;
if ~exist(config.result_directory_clusters_img, 'dir') mkdir(config.result_directory_clusters_img); end;

%names of the trackers that will be used to verify clusters, require config
%files for each tracker, i.e. tracker_FoT.m, tracker_ASMS.m
config.trackers_name = {'KCF'};

config.attributes = {'attribute_aspect_ratio', 'attribute_clutter', 'attribute_illumination_change', 'attribute_size_change', ...
              'attribute_blur', 'attribute_color_change', 'attribute_motion_change', 'attribute_camera_motion', ...
              'attribute_deformation', 'attribute_scene_complexity', 'attribute_motion_absolute'};
config.attributes_legend = {'AR', 'CL', 'IC', 'SC', 'BL', 'CC', 'MC', 'CM', 'DF', 'CO', 'MA'};

config.sequence_selection_attr = [3 4 7 8];        % attributes that need to be uniformly represented in the final sequence selection

config.loadPrevious = 1;           % 0 ... dont load attr. files if there are present, 1 ... load previously computer attr. files
config.validate_by_trackers = 1;   % use tracker performance to show and validate inner-cluster performance
config.hamming_features = 1;       % use feature vector binarization and hamming distance
config.ap_clustering_factor = 1.25; % multiplicative constant for mean similarity in affine prop. clustering (controls number of clusters);
                                    % should be set such that the number of clusters is stable when slightly pertubing this constant (e.g. +-0.05)
config.show_visualization = 1;

config.num_selected_sequences = 60; % number of sequences to be selected

%% init
addpath(genpath('.')); addpath('../'); toolkit_path;

[sequences, experiments] = workspace_load();

%% Preprocess sequences
% remove grayscale sequences and sequences with very small objects
indexes = [];
for i = 1:size(sequences, 2)
    bbox = get_aa_region(sequences{i}, 1);

    area = bbox(3)*bbox(4);
    
    if area <= 400
        fprintf('REMOVE: SMALL AREA (%.0f px^2) in seq %s\n', area, sequences{i}.name);
    end
    if sequences{i}.grayscale == 1
        fprintf('REMOVE: GRAYSCALE SEQ %s\n', sequences{i}.name);
    end
    
    if sequences{i}.grayscale == 0 && area > 400;
        indexes = [indexes i];
    end
end
sequences = sequences(indexes);


%% evaluate trackers for sequence "difficulty" validation
if config.validate_by_trackers == 1
    trackers = tracker_list(config.trackers_name{:});
    workspace_evaluate(trackers, sequences, experiments); 
end

%% compute attributes for each sequence
compute_attributes(config, sequences);

%% perform clustering
%load attributes, normalize feature vectors, compute distances one-to-all
[similarity, sequences, feature_vectors, feature_vectors_realval] = compute_featurevect(config, sequences);

%affine propagation + clustering methods
[clusters_ap, clusters_kmeans] = compute_clusters(config, sequences, similarity, feature_vectors);

%validate clusters by baseline trackers performance
if config.validate_by_trackers == 1
    performance_accumulated = validate_clusters(experiments, sequences, trackers, clusters_ap, clusters_kmeans);
else
    performance_accumulated = zeros(length(sequences), 2); 
end

%% visualize results
visualize_clusters(config, sequences, clusters_ap, performance_accumulated, feature_vectors);

%% automatic sequence selection
sequence_selection(config, sequences, feature_vectors, clusters_ap, performance_accumulated);
