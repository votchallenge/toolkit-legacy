function [color_sequences, grayscale_sequences] = filter_grayscale_sequences(sequences)
% filter_grayscale_sequences Filter grayscale sequences from a set
%
% This function splits the set of sequence descriptors into color and grayscale ones.
%
% Input:
% - sequences (cell): A cell array of sequence descriptors
%
% Output:
% - color_sequences
% - grayscale_sequences (cell

filter = cellfun(@(s) s.grayscale, sequences, 'UniformOutput', true);

color_sequences = sequences(~filter);

grayscale_sequences = sequences(filter);


