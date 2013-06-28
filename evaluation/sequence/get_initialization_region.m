function [region] = get_initialization_region(sequence, index)

region = get_region(sequence, index);

if isfield(sequence, 'noise')

    noise = sequence.noise;

    if length(noise) == 1

        region = region + normrnd(0, noise, size(region, 1), size(region, 2));

    else

        region(:, 1) = region(:, 1) + normrnd(0, noise(1), size(region, 1), 1);
        region(:, 2) = region(:, 2) + normrnd(0, noise(2), size(region, 1), 1);
        region(:, 3) = region(:, 3) + normrnd(0, noise(3), size(region, 1), 1);
        region(:, 4) = region(:, 4) + normrnd(0, noise(4), size(region, 1), 1);

    end;
    
    region = round(region)

end;
