function converted_sequences = convert_sequences(sequences, converter)

if isempty(converter)
    converted_sequences = sequences;
    return;
end;

if ischar(converter)
    converter = str2func(converter);
end;

converted_sequences = cellfun(@(x) converter(x), sequences,'UniformOutput',false);
