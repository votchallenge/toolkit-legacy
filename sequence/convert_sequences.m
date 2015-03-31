function converted_sequences = convert_sequences(sequences, converter)

if isempty(converter)
    converted_sequences = sequences;
    return;
end;

if ischar(converter)
    converter = str2func(converter);
end;

converted_sequences = cellfun(@(x) convert_sequence(x, converter), sequences,'UniformOutput',false);

end

function sequence = convert_sequence(sequence, converter)

    if isfield(sequence, 'converter')
        % If  the sequence is already converted with this converter
        % then do not do it again
        if strcmp(func2str(converter), sequence.converter)
            return;
        end;
    end;

    sequence = converter(sequence);
    
    sequence.converter = func2str(converter);
    
end
