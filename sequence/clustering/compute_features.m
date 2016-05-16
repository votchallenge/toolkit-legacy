function [similarity, sequences, feature_vectors_scaled, feature_vector_realval] = compute_features(config, sequences)
% compute_features Calculates feature vectors for each sequence using the sequence attributes
%
% The function calculates feature representation of each sequence from 
% the computed attributes using the mean_val values as the attribute value for sequence. 
% Computed attributes are stored on local file system.
%
% Input:
% - config (structure): config structure
% - sequence (structure): A valid sequence structure.
%
% Output:
% - similarity (matrix): similarity between all pairs of sequences
% - sequences (structure): modified structure of sequences where the
%   sequences that does not have attributes computed are removed
% - feature_vector_scaled (matrix): feature vector for each sequence
%   (row-wise). If config.hamming_features is set to 1, feature_vector_scaled is binary
%   representation of the feature_vector_realval (clustered to 2 classes) otherwise feature_vector_scaled = feature_vector_realval
% - feature_vector_realval (matrix): (0,1) scaled feature vector

    ready = true(length(sequences), 1);
    numAttr = length(config.attributes);
    feature_vectors = zeros(numAttr, length(sequences));

    for i = 1:length(sequences)

        pfile = fullfile(config.result_directory, sprintf('%s.mean', sequences{i}.name));

        if ~exist(pfile, 'file') 
            ready(i) = 0;
            continue;
        end;

        feature_vectors(:, i) = csvread(pfile);

    end;

    feature_vectors = feature_vectors(:, ready)';
    sequences = sequences(ready);

    sequences = sequences(~any(isnan(feature_vectors), 2));
    feature_vectors = feature_vectors(~any(isnan(feature_vectors), 2), :);

    distances = zeros(size(feature_vectors, 1));

    % scale = max(feature_vectors) - min(feature_vectors);
    % feature_vectors_scaled = (feature_vectors -  ones(size(feature_vectors, 1), 1) * min(feature_vectors)) ./ (ones(size(feature_vectors, 1), 1) * scale);

    feature_vectors_scaled = (feature_vectors - ones(size(feature_vectors, 1),1)*mean(feature_vectors))./(ones(size(feature_vectors, 1),1)*std(feature_vectors));
    scale = max(feature_vectors_scaled) - min(feature_vectors_scaled);
    feature_vectors_scaled = (feature_vectors_scaled -  ones(size(feature_vectors_scaled, 1), 1) * min(feature_vectors_scaled)) ./ (ones(size(feature_vectors_scaled, 1), 1) * scale);

    feature_vector_realval = feature_vectors_scaled;

    if config.hamming_features == 1
        num_cls = 2;
        print_text('Attributes entropy over all sequences : ');
        print_indent(1);
        for i = 1:size(feature_vectors_scaled,2)
            feature_vectors_scaled(:,i) = kmeans( feature_vectors_scaled(:,i), num_cls ) - 1;

            % order k-means clusters id by actuall elements magnitudes
            means = [];
            for j = 1:num_cls
                means = [means mean(feature_vectors(feature_vectors_scaled(:,i) == (j-1), i))];
            end
            [~, id_switch] = sort(means, 'ascend');
            fv_tmp = feature_vectors_scaled(:,i);
            for j = 1:num_cls
                feature_vectors_scaled(fv_tmp == id_switch(j)-1, i) = j-1;
            end

            if max(feature_vectors_scaled(:,i)) > 1
                feature_vectors_scaled(:,i) = feature_vectors_scaled(:,i)./(num_cls-1);
            end
            print_text(' - %s (%.02f)', config.attributes_legend{i}, entropy(feature_vectors_scaled(:,i)));
        end
        print_indent(-1);
    end

    lambda = 1;
    for i = 1:size(feature_vectors, 1)
        for j = 1:i-1
            if config.hamming_features == 1
                distances(i, j) = pdist(feature_vectors_scaled([i j], :), 'hamming');
            else
                distances(i, j) = sqrt(sum(( feature_vectors_scaled(i, :) - feature_vectors_scaled(j, :)) .^2));    
            end
            distances(j, i) = distances(i, j);
        end;
    end;

    similarity = - distances;
end





