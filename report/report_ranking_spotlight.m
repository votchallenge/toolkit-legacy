function [document] = report_ranking_spotlight(context, trackers, sequences, experiments, spotlight, varargin)
% report_ranking Generate a spotlight report based on A-R ranking 
%
% Performs A-R ranking analysis and generates a spotlight report for a given tracker.
%
% Input:
% - context (structure): Report context structure.
% - trackers (cell): An array of tracker structures.
% - sequences (cell): An array of sequence structures.
% - experiments (cell): An array of experiment structures.
% - spotlight (string): Identifier of a tracker in the input tracker set that will be spotlighted.
% - varargin[UsePractical] (boolean): Use practical difference.
% - varargin[Average] (boolean): Averaging type.
% - varargin[Alpha] (boolean): Statistical significance parameter.
%
% Output:
% - document (structure): Resulting document structure.
%

usepractical = false;

alpha = get_global_variable('report_ranking_alpha', 0.05);

for i = 1:2:length(varargin)
    switch lower(varargin{i}) 
        case 'usepractical'
            usepractical = varargin{i+1};
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

for e = 1:length(experiments)

    result = analyze_ranks(experiments{e}, trackers, ...
        sequences, 'usepractical', usepractical, ...
        'alpha', alpha);

    document.section('Experiment %s', experiments{e}.name);
    
    table = cell(numel(result.labels), 2);
        
    for i = 1:numel(result.labels)
    
        [accuracy_description, accuracy_css] = categorize_order(result.accuracy.ranks(i, :), spotlight_index);
        [robustness_description, robustness_css] = categorize_order(result.robustness.ranks(i, :), spotlight_index);

        table{i, 1} = struct('text', accuracy_description, 'class', accuracy_css);
        table{i, 2} = struct('text', robustness_description, 'class', robustness_css);
                        
    end

    document.table(table, 'columnLabels', {'Accuracy', 'Robustness'}, 'rowLabels', result.labels');
        
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

