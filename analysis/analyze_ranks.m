function [result] = analyze_ranks(experiment, trackers, sequences, varargin)

usepractical = false;
uselabels = true;
average = 'mean';

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'uselabels'
            uselabels = varargin{i+1} ;             
        case 'usepractical'
            usepractical = varargin{i+1} ;  
        case 'average'
            average = varargin{i+1} ;              
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

print_text('Ranking analysis for experiment %s ...', experiment.name);

print_indent(1);

experiment_sequences = convert_sequences(sequences, experiment.converter);

if isfield(experiment, 'labels') && uselabels

    selectors = create_label_selectors(experiment, ...
        experiment_sequences, experiment.labels);

else

    selectors = create_sequence_selectors(experiment, experiment_sequences);

end;

[accuracy, robustness] = trackers_ranking(experiment, trackers, ...
    experiment_sequences, selectors, 'usepractical', usepractical, 'average', average);

result = struct('accuracy', accuracy, 'robustness', robustness);

print_indent(-1);