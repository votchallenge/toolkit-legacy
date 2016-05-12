function [] = run_clustering()
% run_clustering perform the automatic sequence clustering procedure in the current workspace
%
% This method runs the whole process of automatic sequence selection in the
% current workspace. It assume that the sequences - to be clustered - are
% presented in a valid form in the workspace (i.e. "sequence" directory with the list.txt
% file containing names of all sequences).
%
% Setup of the parameters for clustering:
% - initialize toolkit path and load current workspace 
%   (global variables, sequences and experiments based on configuration.m file),
%   note that experiment stack need to be set to 'clustering' in configuration.m if trackers are 
%   used to estimate sequence difficulty during sequence selection process.
% - sets config structure which contains all parameters for the
%   automatic sequence selection algorithm. 
% - individual parameters are described and commented in this
%   section and are set to default values that were used in the
%   automatic sequence selection used for VOT2015.
% - removes sequences with small objects (initial area <= 400) and
%   grayscale images
%
% Input:
% - dataset of the sequences to be processed in the valid VOT format in the
%   sequence directory of the workspace where this function is called
% - (optional) tracker algorithms to be used for computation of sequence
%   difficulty
%
% Output:
% - 'final_selection.txt' file with the selected sequences in the directory
%   specified in the config.result_base_dir variable


    %% init
    toolkit_path;
    [sequences, experiments] = workspace_load();

    %% set environment variables (sequence dir, result output dir, ...)

    %prepare the directories where to store the results of sequence clustering
    config.result_base_dir = './clustering_results'; %main dir
    config.result_directory = [ config.result_base_dir '/attributes/']; %contains computed attributes
    config.result_directory_clusters_img = [ config.result_base_dir '/clusters_imgages/']; %for images of clusters
    
    if ~exist(config.result_base_dir, 'dir') mkdir(config.result_base_dir); end;
    if ~exist(config.result_directory, 'dir') mkdir(config.result_directory); end;
    if ~exist(config.result_directory_clusters_img, 'dir') mkdir(config.result_directory_clusters_img); end;

    % names of the trackers that will be used to verify clusters, require config
    % files for each tracker, i.e. tracker_FoT.m, tracker_ASMS.m
    % NOTE: used only if the config.validate_by_trackers flag is set to 1
    config.trackers_name = {'KCF'}; 

    %names of attributes that should be computed, note that each name have
    %to correspond to the matlab funtion located in sequences/clustering/attributes (or in path visible to matlab) 
    %that perform the attribute computation.
    config.attributes = {'attribute_aspect_ratio', 'attribute_clutter', 'attribute_illumination_change', 'attribute_size_change', ...
                  'attribute_blur', 'attribute_color_change', 'attribute_motion_change', 'attribute_camera_motion', ...
                  'attribute_deformation', 'attribute_scene_complexity', 'attribute_motion_absolute'};
    
    %short-cuts of the attribute names that are used in legend of plots
    config.attributes_legend = {'AR', 'CL', 'IC', 'SC', 'BL', 'CC', 'MC', 'CM', 'DF', 'CO', 'MA'};

    % indexes to the config.attributes of the attributes that need to be uniformly represented in the final sequence selection
    config.sequence_selection_attr = [3 4 7 8];        

    config.loadPrevious = 1;            % 0 ... do not use already computed attributes 
                                        % 1 ... load previously computed attributes
                                       
    config.validate_by_trackers = 1;    % use tracker performance for sequence difficulty estimation 
                                        % (shown in plots and used during final sequence selection)
                                       
    config.hamming_features = 1;        % use feature vector binarization and hamming distance as a feature vectors metric
                                        % otherwise the feature vector is normalized to (0,1) range and Eucledian distance is used
                                        
    config.ap_clustering_factor = 1.25; % multiplicative constant of the mean similarity threshold in the affine propagation clustering algorithm
                                        % This parameter controls the number of clusters that are produced
                                        % should be set such that the number of clusters is stable when slightly pertubing this constant (e.g. +-0.05)
                                        
    config.show_visualization = 1;      % plot the clusters with examples of images from each sequence

    config.num_selected_sequences = 60; % number of sequences to be selected

    %% Preprocess sequences
    % remove grayscale sequences and sequences with very small objects
    indexes = [];
    for i = 1:size(sequences, 2)
        bbox = region_convert(get_region(sequences{i}, 1), 'rectangle');

        area = bbox(3)*bbox(4);

        if area <= 400
            print_text('REMOVE: object area too small (%.0f px^2) in sequence %s\n', area, sequences{i}.name);
        end
        if sequences{i}.grayscale == 1
            print_text('REMOVE: grayscale sequence %s\n', sequences{i}.name);
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
    [similarity, sequences, feature_vectors, feature_vectors_realval] = compute_features(config, sequences);

    %affine propagation + clustering methods
    [clusters_ap, clusters_kmeans] = compute_clusters(config, sequences, similarity, feature_vectors);

    %compute performance difficulty of sequences by running baseline trackers using VOT methodology
    if config.validate_by_trackers == 1
        performance_accumulated = compute_performance_difficulty(experiments, sequences, trackers, clusters_ap, clusters_kmeans);
    else
        performance_accumulated = zeros(length(sequences), 2); 
    end

    %% visualize results
    visualize_clusters(config, sequences, clusters_ap, performance_accumulated, feature_vectors);

    %% automatic sequence selection
    sequence_selection(config, sequences, feature_vectors, clusters_ap, performance_accumulated);

end
