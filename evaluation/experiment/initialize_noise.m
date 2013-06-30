function [region] = initialize_noise(sequence, index)

region = get_region(sequence, index, context);

noise = [0, 0, 1, 1];

if isfield(sequence, 'noise')

    noise = squeeze(sequence.noise(mod(index, size(sequence.noise, 1)), :));
    
end;


region(1:2) = region(1:2) + region(3:4) .* noise(1:2);
region(3:4) = region(3:4) .* noise(3:4);

region = round(region);
