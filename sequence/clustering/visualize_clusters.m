function [] = visualize_clusters(config, sequences, clusters, performance_accumulated, feature_vectors_scaled)
% visualize_clusters Saves sequences per cluster in a text file. 
% 
% Saves sequences per cluster in a text file and visualizes the sequences for individual clusters with object previews and save them as images.
%
% This function 1) saves for each cluster a list of sequences that
% belong to that cluster and their difficulty and feature vectors. 
% 2) plots (if config.show_visualization == 1) a figures illustrating all 
% seaquences for each cluster with sequence difficulty, attributes 
% distribution and object preview for each sequence.
%
%
% Input:
% - config (structure): config structure
% - sequences (cell): An array of sequence structures.
% - clusters (structure): clustering structure from compute_clusters function (clusters_ap was used for VOT)
% - performance_accumulated (matrix): average quantized robustness and accuracy for each sequence (row-wise)
% - feature_vector_scaled (matrix): feature vector for each sequence (row-wise).
% 
% Output:
% - 'all_clusters.txt' file with the clusters, sequences and their difficulty and feature vectors
%   for each cluster in the directory specified in the config.result_base_dir variable
% - (optional if config.show_visualization == 1) 'cluster-XX_*.png' visualization of the sequences 
%   for each cluster saved in the directory defined by config.result_directory_clusters_img variable
%

    exemplars_vis = clusters.exemplars;
    cluster_map_vis = clusters.cluster_map;
    numAttr = length(config.attributes);

    if config.show_visualization == 1
        for e = 1:length(exemplars_vis)
            figure(1);
            clf
            hold on;

            cluster_part = 0;
            j = 0;
            num_seq_in_cluster = min([6 length(find(cluster_map_vis == exemplars_vis(e)))]);

            % order sequences by performance
            cluster_seq_id = find(cluster_map_vis == exemplars_vis(e))';
            cluster_seq_perf = sum(performance_accumulated(cluster_seq_id,:),2);
            [~, I] = sort(cluster_seq_perf, 'ascend');

            for sq = cluster_seq_id(I);
                j = j + 1;

                num_img_per_seq = 4;
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
                axis([1 numAttr 0 1]);
                axis tight;
                title(['Sequence attributes']);
                set(gca, 'XTick', [1:numAttr]+0.3);
                set(gca, 'YTick', [0 0.5 1]);
                set(gca, 'XTickLabel', config.attributes_legend);
                rotateXLabels(gca, 90);
                bar(feature_vectors_scaled(sq,:), 'r');
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

                    if any(exemplars_vis == sq)
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

                    name = [config.result_directory_clusters_img '/cluster-' sprintf('%02d', e) '_' num2str(cluster_part, '%02d')];
                    export_fig([name '.png'], gcf, '-nocrop');

                    if (length(find(cluster_map_vis == exemplars_vis(e)))-6*(cluster_part+1) > 0)
                        figure(1);
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
            name = [config.result_directory_clusters_img '/cluster-' sprintf('%02d', e) '_' num2str(cluster_part, '%02d')];
            if cluster_part == 0
                name = [config.result_directory_clusters_img '/cluster-' sprintf('%02d', e) '_all'];
            end
            export_fig([name '.png'], gcf, '-nocrop');

            %if cluster_part > 0
            %    system(['montage -tile 1x' num2str(cluster_part+1) ' -geometry +0-20 "' result_directory_clusters_img '/cluster-' sprintf('%02d', e) '_*.png" "' result_directory_clusters_img '/cluster-' sprintf('%02d', e) '_all.png"']);
            %end
            %saveas(gcf, name, 'png');
            %print(gcf, name,'-dpng','-r0')
        end;
    end
    
    out_file = fopen([config.result_base_dir '/all_clusters.txt'], 'w');
    for e = 1:length(exemplars_vis)
        % order sequences by performance
        cluster_seq_id = find(cluster_map_vis == exemplars_vis(e))';
        cluster_seq_perf = sum(performance_accumulated(cluster_seq_id,:),2);
        [~, I] = sort(cluster_seq_perf, 'ascend');

        for sq = cluster_seq_id(I);
            fprintf(out_file, '%02d, %s, %0.1f, %0.1f', e, sequences{sq}.name, performance_accumulated(sq,1), performance_accumulated(sq,2));
            for k = 1:size(feature_vectors_scaled,2)
                fprintf(out_file, ', %d', feature_vectors_scaled(sq, k));
            end
            fprintf(out_file, '\n');
        end
    end
    fclose(out_file);

end
