function [document, highlights] = report_ranking_spotlight(context, trackers, sequences, experiments, spotlight, varargin)

uselabels = false;
usepractical = false;
average = 'weighted_mean';
alpha = 0.05;

for i = 1:2:length(varargin)
    switch lower(varargin{i}) 
        case 'usepractical'
            usepractical = varargin{i+1};
        case 'uselabels'
            uselabels = varargin{i+1};
        case 'average'
            average = varargin{i+1};
        case 'alpha'
            alpha = varargin{i+1}; 
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end 

spotlight_index = find_tracker(trackers, spotlight);

if isempty(spotlight_index)
    error('Spotlight tracker not found!');
end;

spotlight_tracker = trackers{spotlight_index};

document = create_document(context, sprintf('ranking_spotlight_%s', spotlight_tracker.identifier), ...
    'title', sprintf('Ranking spotlights for tracker %s', spotlight_tracker.label));

highlights = cell(length(experiments), 1);

for e = 1:length(experiments)

    result = analyze_ranks(experiments{e}, trackers, ...
        sequences, 'uselabels', uselabels, 'usepractical', usepractical, ...
        'average', average, 'alpha', alpha, 'cache', context.cachedir);

    document.section('Experiment %s', experiments{e}.name);
    
    table = cell(numel(result.robustness.labels), 2);
        
    for i = 1:numel(result.robustness.labels)
    
        [accuracy_description, accuracy_css] = categorize_order(result.accuracy.ranks(i, :), spotlight_index);
        [robustness_description, robustness_css] = categorize_order(result.robustness.ranks(i, :), spotlight_index);

        table{i, 1} = struct('text', accuracy_description, 'class', accuracy_css);
        table{i, 2} = struct('text', robustness_description, 'class', robustness_css);
                        
    end

    document.table(table, 'columnLabels', {'Accuracy', 'Robustness'}, 'rowLabels', result.robustness.labels');
        
end;

document.write();

end


function [description, css] = categorize_order(ranks, selection)

    [~, O] = sort(ranks, 'ascend');

    value = (ranks(selection) - median(ranks)) / length(ranks);

    if value > 0.2
    
        description = 'Below average';
        css = 'bad';
        
    elseif value < -0.2
        
        description = 'Above average';
        css = 'good';
        
    else 
        description = 'Average';
        css = 'average';
    end

    description = sprintf('%s (%d of %d)', description, find(O == selection, 1), length(O));
    
end

