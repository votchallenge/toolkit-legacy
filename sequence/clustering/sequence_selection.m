function [] = sequence_selection(config, sequences, feature_vectors_scaled, clusters_struct, performance_accumulated)
% sequence_selection Algorithm for automatic sequence sampling from clusters using greedy approach
%
% The algoritem selects the most difficult sequences from each cluster.
%
% ## Description of the algorithm
%
% Prerequisites:
% - Apply sequence clustering from automatically calculated attributes 
%   (without occlusion attribute) using the AP and Hamming distance.
% - We get K clusters and each cluster contains N_k sequences. We need to get a 
%   dataset of M sequences that are proportionally sampled from the clusters as follows.
% - Compute the final maximal number of sequences that are allowed 
%   to be sampled from each cluster as floor(N_k*M/N_all).
%
% Initialization:
% - Initialize the dataset by taking the hardest sequence from each cluster.
% 
% Main loop:
% - Compute the average attribute vector of the selected sequences. Normalize this vector so that it sums to 1 
%   (denote this as a balance vector). This gives for each attribute a value between 0 and 1 indicating how much of the 
%   particular attribute is present in the selected dataset.
% - Identify the attribute that is least represented in the selected set of sequences (find minimum on the ballance vector). 
%   There may be several equally poorly presented attributes. Use the following equation, let h = [h1 h2 h3] 
%   be the ballence vector. Modify the vector by h/h_max, where h_max is the most presented attribute and then select all attributes 
%   that give 1 from the following relation  h<(h_min+0.1/nc) -- the hysteresis of +0.1/nc gives 10% of uniform 
%   distribution for nc classes (nc = number of attributes used for sampling -- config.sequence_selection_attr)
% - Among all remaining sequences in all clusters identify the sequences that contain the missing identified 
%   attributes (ignore the clusters whose final number of sampled sequences has been reached).
% - From the set of sequences from step (7) select the sequence with the highest level of difficulty and add it to the new dataset.
% - Go back to step 5 and continue until you reach a dataset with M sequences.
%
% Input:
% - config (structure): config structure 
% - sequences (cell): an array of sequence structures.
% - feature_vectors_scaled (matrix #sequences x #num_attributes): feature vector for each sequence (row-wise)
% - clusters_struct (structure): clustering structure from compute_clusters function (clusters_ap was used for VOT)
% - performance_accumulated (matrix #sequences x 2): average quantized robustness and accuracy for each sequence (row-wise)
%
% Output:
% - 'final_selection.txt' file with the selected sequences in the directory
%   specified in the config.result_base_dir variable
% - (optional if config.show_visualization == 1) 'cluster-selection_*.png' visualization of the selected
%   sequences in the config.result_directory_clusters_img directory

%% prefix removal for freq. used var.
    sequence_selection_attr = config.sequence_selection_attr;
    attributes_legend = config.attributes_legend;
    exemplars = clusters_struct.exemplars;
    cluster_map = clusters_struct.cluster_map;

%% ADD OCCLUSION ATTRIBUTE - used in the VOT2015 sequence selection, occlusion was manually labeled
%     fileID = fopen('list_output_occlusion_20_30_40.txt');
%     O = textscan(fileID,'%s %d %d %d', 'Delimiter', ',');
%     fclose(fileID);
%     names = O{1};
% 
%     occlusion_feat = [];
%     for i = 1:size(sequences,2);
%         id = find(strcmpi(sequences{i}.name, names));
%         if ~isempty(id)
%             occlusion_feat(end+1,1) = O{2}(id);
%         else
%             print_text('Missing seqence %s \n', sequences{i}.name);
%         end
%     end
% 
%     feature_vectors_scaled = [feature_vectors_scaled occlusion_feat];
%     sequence_selection_attr = [sequence_selection_attr size(feature_vectors_scaled,2)];
%     attributes_legend = [attributes_legend {'O'}];
% 

%% ALG
    % sequence_selection_attr = [CM, IC, MC, SC, O]    ... attributes that we are trying to ballance in the dataset

    % 1..3
    N_all = size(sequences, 2);     %number of all sequences for clustering
    M = min([config.num_selected_sequences  size(sequences,2)]); % number of desired sequences
    num_clusters = size(exemplars, 2);

    clusters_sampling_count = zeros(num_clusters, 1);
    clusters_sampled = zeros(num_clusters, 1);
    N_k = zeros(num_clusters, 1);

    % 4
    selection.sequences_id = [];
    selection.clusters_id = [];

    feature_weights = size(feature_vectors_scaled, 1)./sum(feature_vectors_scaled, 1);%ones(1, size(feature_vectors_scaled, 2));

    seq_to_cluster_mapping = zeros(length(cluster_map), 1);

    for i = 1:num_clusters
        N_k(i) = sum(cluster_map == exemplars(i));
        clusters_sampling_count(i) = ceil(N_k(i)*M/N_all);

        % order sequences by performance
        cluster_seq_id = find(cluster_map == exemplars(i))';
        seq_to_cluster_mapping(cluster_seq_id) = i;
        cluster_seq_perf = sum(performance_accumulated(cluster_seq_id,:),2);
        [~, I] = sort(cluster_seq_perf, 'descend');

        selection.sequences_id(end+1) = cluster_seq_id(I(1));
        selection.clusters_id(end+1) = i;

        clusters_sampled(i) = clusters_sampled(i) + 1;
    end

    % 5-9
    for i = 1:(M-num_clusters)
        % 5
        balance_vector = sum(feature_vectors_scaled(selection.sequences_id, sequence_selection_attr), 1) .* feature_weights(sequence_selection_attr);
        balance_vector = balance_vector/max(balance_vector);

        % 6
        want_feat = (balance_vector < (min(balance_vector)+0.1/length(sequence_selection_attr)));
        if (sum(want_feat) == 0)
            want_feat = ones(1, length(sequence_selection_attr));
        end

        % 7
        distance = zeros(size(feature_vectors_scaled, 1), 1);
        for j = 1:size(feature_vectors_scaled, 1)
           distance(j) = pdist([want_feat; feature_vectors_scaled(j, sequence_selection_attr)], 'hamming'); 
        end

        % find sequences with the most similar feature vectors that are not in
        % the selection and the cluster is not oversampled
        min_seq_idxs = [];
        first_run = true;
        while isempty(min_seq_idxs)
            if ~first_run
                distance(distance == min(distance)) = 100;
            end
            min_seq_idxs = find(distance == min(distance));
            [~, IA, ~] = intersect(min_seq_idxs, selection.sequences_id);
            min_seq_idxs(IA) = [];
            sample_weight = clusters_sampling_count(seq_to_cluster_mapping(min_seq_idxs)) - clusters_sampled(seq_to_cluster_mapping(min_seq_idxs));
            if sum(sample_weight) == 0
                min_seq_idxs = [];
            end
            first_run = false;
        end

        max_sw_idxs = find(sample_weight == max(sample_weight));

        % 8 
        cluster_seq_perf = sum(performance_accumulated(min_seq_idxs(max_sw_idxs),:),2);
        [~, I] = sort(cluster_seq_perf, 'descend');
        %TODO: if multiple sequence have the same difficulty take random one
        add_seq_id = min_seq_idxs(max_sw_idxs(I(1)));

        selection.sequences_id(end+1) = add_seq_id;
        selection.clusters_id(end+1) = seq_to_cluster_mapping(add_seq_id);
        clusters_sampled( seq_to_cluster_mapping(add_seq_id)) = clusters_sampled( seq_to_cluster_mapping(add_seq_id)) + 1;

    end


%% visualize selection
    cluster_part = 0;
    num_seq_in_cluster = 6;

    % order sequences by performance
    cluster_seq_id = selection.sequences_id;
    cluster_seq_perf = sum(performance_accumulated(cluster_seq_id,:),2);
    [~, I] = sort(cluster_seq_perf, 'ascend');

    cluster_seq_cluster = selection.clusters_id(I); 

    if config.show_visualization == 1
        figure(2);
        hold on;

        j = 0;
        ii = 0;
        for sq = cluster_seq_id(I);
            ii = ii + 1;
            j = j + 1;

            num_img_per_seq = 5;
            sub_plot_cols = num_img_per_seq + 2;

            subplot(num_seq_in_cluster, sub_plot_cols, sub_plot_cols*(j-1) + 1);
            hold on;
            axis([1 2 0 9]);
            axis tight;
            bar(performance_accumulated(sq,:), 'b');
            title(['Sequence difficulty (' num2str(performance_accumulated(sq,1), '%0.1f') ' | ' num2str(performance_accumulated(sq,2), '%0.1f') ')']);
            set(gca, 'XTick', [1.25 1.75]);
            set(gca, 'YTick', [0:3:9]);
            set(gca, 'XTickLabel', {'ROB' 'ACC'});
            hold off;        

            subplot(num_seq_in_cluster, sub_plot_cols, sub_plot_cols*(j-1) + 2);
            hold on;
            axis([1 length(sequence_selection_attr) 0 1]);
            axis tight;
            title(['Sequence attributes']);
            set(gca, 'XTick', [1:length(sequence_selection_attr)]+0.3);
            set(gca, 'YTick', [0 0.5 1]);
            set(gca, 'XTickLabel', attributes_legend(sequence_selection_attr));
            rotateXLabels(gca, 90);
            bar(feature_vectors_scaled(sq,sequence_selection_attr), 'r');
            hold off;        

            for i = 1:num_img_per_seq
                subplot(num_seq_in_cluster, sub_plot_cols, sub_plot_cols*(j-1) + i + 2);

                image_index = (i-1)*floor(sequences{sq}.length/num_img_per_seq) + 1;
                image = get_image(sequences{sq}, image_index);
                gt = region_convert(get_region(sequences{sq}, image_index), 'rectangle');
                imshow(image);
                if (~isnan(gt(1)))
                    rectangle('Position',gt, 'LineWidth',1, 'EdgeColor','g');
                end

                if any(exemplars == sq)
                    title(['*** ' strrep(sequences{sq}.name, '_', '\_'), ' (', num2str(image_index), '/', num2str(sequences{sq}.length),  ')']); 
                else    
                    title([strrep(sequences{sq}.name, '_', '\_'), ' (', num2str(image_index), '/', num2str(sequences{sq}.length),  ')']);
                end;

            end

            if j >= 6
                set(gcf,'units','pixel');
                set(gcf,'position',[0 0 4*480 num_seq_in_cluster*480]);
                set(gcf,'papersize',[4*480 num_seq_in_cluster*480]);

                drawnow;
                hold off;

                name = [config.result_directory_clusters_img '/cluster-selection_' num2str(cluster_part, '%02d')];
                export_fig([name '.png'], gcf, '-nocrop');

                if (length(selection.sequences_id)-6*(cluster_part+1) > 0)
                    figure(2);
                    clf
                    hold on;
                    j = 0;   
                    cluster_part = cluster_part + 1;
                end
            end
        end;

        set(gcf,'units','pixel');
        set(gcf,'position',[0 0 4*480 num_seq_in_cluster*480]);
        set(gcf,'papersize',[4*480 num_seq_in_cluster*480]);

        drawnow;
        hold off;
        name = [config.result_directory_clusters_img '/cluster-selection_' num2str(cluster_part, '%02d')];
        export_fig([name '.png'], gcf, '-nocrop');

        %if cluster_part > 0
        %    system(['montage -tile 1x' num2str(cluster_part+1) ' -geometry +0-20 "' result_directory_clusters_img '/cluster-selection_*.png" "' result_directory_clusters_img '/cluster-selection_all.png"']);
        %end
        %saveas(gcf, name, 'png');
        %print(gcf, name,'-dpng','-r0')

    end
    
    out_file = fopen([config.result_base_dir '/final_selection.txt'], 'w');
    for sq = cluster_seq_id(I);
        fprintf(out_file, '%02d, %s, %0.1f, %0.1f', cluster_seq_cluster(ii), sequences{sq}.name, performance_accumulated(sq,1), performance_accumulated(sq,2));
        for k = 1:size(feature_vectors_scaled,2)
            fprintf(out_file, ', %d', feature_vectors_scaled(sq, k));
        end
        fprintf(out_file, '\n');
    end
    fclose(out_file);   
    
end




