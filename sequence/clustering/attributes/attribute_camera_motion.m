function [mean_val, var_val, frames] = attribute_camera_motion(sequence)
% attribute_camera_motion Computes the camera motion attribute in the given seqeunce
%
% Camera motion is defined as the average of translation vector lengths 
% estimated by key-point-based RANSAC between consecutive frames.
%
% Input:
% - sequence (struct): An array of sequence structures.
%
% Output:
% - mean_val : mean value of the camera motion for the sequence
% - val_val  : variance of the camera motion for the sequence
% - frames   : the camera motion for each frame (from t-1 to t)

    patchSize = 9;
    maxFeatures = 1000;
    maxFeatEuclDistance = 30;

    ransac_iter = 1000;
    ransac_thr2 = 9;
    ransac_prob = 0.95;


    frames = zeros(sequence.length, 1);

    image1 = rgb2gray(imread(get_image(sequence, 1)));
    image1Corners = corner(image1, maxFeatures);
    image1Patches = extractPatches(image1Corners, patchSize, image1);

    frame(1) = 0;

    for i = 2:sequence.length
        image2 = rgb2gray(imread(get_image(sequence, i)));
        image2Corners = corner(image1, maxFeatures);
        image2Patches = extractPatches(image2Corners, patchSize, image1);
        
        [idx1, idx2] = matchFeatures(image1Corners, image2Corners, image1Patches, image2Patches, maxFeatEuclDistance);
        aff = ransac(image1Corners(idx1,:), image2Corners(idx2, :), ransac_iter, ransac_thr2, ransac_prob);
        
        frames(i) = sqrt(aff(1,3)^2 + aff(2,3)^2);
        
        image1 = image2;
        image1Corners = image2Corners;    
        image1Patches = image2Patches;
    end;

    mean_val = mean(frames(2:end));
    var_val = var(frames(2:end));


function [patches] = extractPatches(corners, patchSize, image)
    
    patches = zeros(patchSize, patchSize, size(corners, 1));    
    removeBorder = [];
    for i = 1:size(corners, 1)
        if (corners(i,1)-patchSize > 0 && corners(i,1)+patchSize <= size(image,2) && ...
            corners(i,2)-patchSize > 0 && corners(i,2)+patchSize <= size(image,1))
            
            rangeY = (corners(i,2)-floor(patchSize/2)):(corners(i,2)+floor(patchSize/2));
            rangeX = (corners(i,1)-floor(patchSize/2)):(corners(i,1)+floor(patchSize/2));
            patches(:,:,i) = image(rangeY,rangeX);
        end
    end


function [idx1, idx2] = matchFeatures(pt1, pt2, desc1, desc2, maxDistance)
    idx1 = [];
    idx2 = [];
    D = pdist2(pt1,pt2, 'euclidean');

    for i = 1:size(pt1,1)
        closest = find(D(i,:) < maxDistance);
        maxSim = -2;
        maxSimId = -1;
        for j = 1:length(closest)
            sim = corr2(desc1(:,:,i), desc2(:,:,closest(j)));
            if (sim > maxSim)
                maxSim = sim;
                maxSimId = closest(j);
            end
        end
        if (maxSimId > 0)
            idx1 = [idx1 i];
            idx2 = [idx2 maxSimId];
        end
    end


function [A] = ransac(pt1, pt2, iter, thr2, prob)
    samples=0;
    A = zeros(2,3);
    num_samples=iter;
    num_pts = size(pt1,1);
    num_inl = 0;
    minSamples = 3;

    if num_pts < minSamples
        return;
    end
    
    while samples<num_samples
        pom = randperm(num_pts);
        s = pom(1:minSamples);
        
        As = u2a(pt1(s,:), pt2(s,:));
        dst = adist(As, pt1, pt2);

        if (num_inl < sum(dst<thr2))         
            % remember inliers...
            A = As;
            inl = dst<thr2; num_inl = sum(inl);
            % local optimisation, take all precise points and reestimate
            Alo = u2a(pt1(dst<thr2,:), pt2(dst<thr2,:));
            dstlo = adist(Alo, pt1, pt2);
            if (sum(dstlo<thr2) > num_inl)
                % a better model was found
                A=Alo; inl = dstlo<thr2; num_inl = sum(inl);
            end;

            q  = prod ([(num_inl-minSamples+1) : num_inl] ./ [(num_pts-minSamples+1) : num_pts]);
            if q > eps
               SampleCnt  = log(1 - prob) / log(1 - q);
               if SampleCnt < num_samples
                    num_samples = 1;
                end
            end
        end
        samples = samples+1;
    end

function [A] = u2a(pt1, pt2)
    X = zeros(2*size(pt1,1), 6);
    Y = zeros(2*size(pt1,1), 1);
    for i = 1:2:size(pt1,1)
        X(i, :) = [pt1(ceil(i/2), 1) pt1(ceil(i/2), 2) 1 0 0 0];
        X(i+1, :) = [0 0 0 pt1(ceil(i/2), 1) pt1(ceil(i/2), 2) 1];
        Y(i) = pt2(ceil(i/2), 1);
        Y(i+1) = pt2(ceil(i/2), 2);
    end
    A = reshape(pinv(X)*Y,[2 3]);

function dist = adist(A,pt1,pt2)
   pts = A*[pt1 ones(size(pt1,1), 1)]';
   pts = pts';
   dist = sum((pts(:,1:2)-pt2(:,1:2)).^2, 2);