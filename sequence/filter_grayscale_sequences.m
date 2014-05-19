function [color_sequences, grayscale_sequences] = filter_grayscale_sequences(sequences)

    filter = cellfun(@(s) s.grayscale, sequences, 'UniformOutput', true);

    color_sequences = sequences(~filter);
    
    grayscale_sequences = sequences(filter);


