function [clusters_ap, clusters_kmeans] = compute_clusters(config, sequences, similarity, feature_vectors);
% compute_clusters clusters the sequences based on feature vectors using
% two methods (affine propagation and k-means)
%
% The function compute clusters based on sequence similarity defined by the
% feature vector. Two unsupervised clustering algorithms are used, affine
% propagation and k-means. The number of clusters for k-means is set to be
% the same as for affine propagation. Number of clusters for affine
% propagation is controled by the config.ap_clustering_factor variable. The
% config.ap_clustering_factor should be set such that small pertubation of
% this variable does not change the number of clusters (significantly).
%
% Input:
% - config (structure): config structure
% - sequence (structure): A valid sequence structure.
% - similarity (matrix): similarity between every pair of the sequence feature vector
% - feature_vectors (matrix): feature vector for each sequence
%
% Output:
% - clusters_ap (structure): clustering of the affine propagation method
% - clusters_kmeans (structure): clustering of the k-mean method
%   
% Clusters structure:
% - cluster_map (vector): assignment of each sequence to some exemplar
% - exemplars (vector): representants of the clusters
% - clusters_id (cell vector): ids of sequences for each cluster 
%

%affine propagation
    p = config.ap_clustering_factor*mean(similarity(:));  % effects number of clusters
    clusters_ap.cluster_map = apcluster(similarity, p);
    clusters_ap.exemplars = unique(clusters_ap.cluster_map)';
    print_text('Number of AP clusters: %d', length(clusters_ap.exemplars));

    %k-means
    numClusters = length(clusters_ap.exemplars);
    clusters_kmeans.cluster_map = kmeans(feature_vectors, numClusters);
    clusters_kmeans.exemplars = unique(clusters_kmeans.cluster_map)';
    print_text('Number of k-means clusters: %d', numClusters);

    clusters_ap.clusters_id = cell(length(clusters_ap.exemplars), 1);
    clusters_kmeans.clusters_id = cell(length(clusters_ap.exemplars), 1);

    cmax = 0;
    fileID = fopen([config.result_base_dir '/clusters_ap.list'],'w');
    fileID_k = fopen([config.result_base_dir '/clusters_kmeans.list'],'w');

    for e = 1:length(clusters_ap.exemplars)
        %exemplars_ap(e)
        cluster_id = find(clusters_ap.cluster_map == clusters_ap.exemplars(e));
        clusters_ap.clusters_id(e) = {cluster_id};
        cmax = max(cmax, sum(clusters_ap.cluster_map == clusters_ap.exemplars(e)));

        for j = 1:length(cluster_id)-1
            fprintf(fileID, '%s, ', sequences{cluster_id(j)}.name);
        end
        fprintf(fileID, '%s\n', sequences{cluster_id(end)}.name);

        cluster_id_k = find(clusters_kmeans.cluster_map == clusters_kmeans.exemplars(e));
        clusters_kmeans.clusters_id(e) = {cluster_id_k};

        for j = 1:length(cluster_id_k)-1
            fprintf(fileID_k, '%s, ', sequences{cluster_id_k(j)}.name);
        end
        fprintf(fileID_k, '%s\n', sequences{cluster_id_k(end)}.name);
    end;

    fclose(fileID);
    fclose(fileID_k);
end

