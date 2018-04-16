function workspace_analyze(trackers, sequences, experiments, identifier, varargin)
% workspace_analyze Perform analysis of the experimental results in the workspace
%
% Perform analysis of the
%
% Input:
% - trackers (cell or structure): Array of tracker structures.
% - sequences (cell or structure): Array of sequence structures.
% - experiments (cell or structure): Array of experiment structures.
% - identifier (string): Analysis report identifier.
%

%for j=1:2:length(varargin)
%    switch lower(varargin{j})
%        otherwise, error(['unrecognized argument ', varargin{j}]);
%    end
%end

context = document_context(identifier);

table_scores = {};

table_data = nan(numel(trackers), 0);

tracker_labels = cellfun(@(x) iff(isfield(x.metadata, 'verified') && x.metadata.verified, [x.label, '*'], x.label), trackers, 'UniformOutput', false);

list_experiments = {};

table_analysis = {};
table_analysis_sorting = {};
table_analysis_count = [];

table_experiment_count = [];

for e = 1:numel(experiments)
	experiment = experiments{e};

    print_text('Experiment %s', experiment.name);
    
    print_indent(1);
    
    analyses = convert_metadata(experiment.analysis);
    
    list_analysis = {};
    
    k = sum(table_analysis_count);
    
    for a = 1:numel(analyses)
        analysis = analyses{a};

        report_type = ['report_', analysis.type];
        
        try
            report_function = str2func(report_type);
        catch
            continue;
        end;

        print_text('Analysis %s', analysis.type);

        print_indent(1);
        
        context.prefix = [experiment.name , '_', analysis.type, '_'];
        
        [document, scores] = report_function(context, experiment, trackers, sequences, analysis.parameters{:});

        list_analysis{end+1} = document; %#ok<AGROW>
            
        if ~isstruct(scores)
            print_indent(-1);
            continue;
        end;

        table_analysis{end + 1} = scores.name; %#ok<AGROW>
        
        table_analysis_count(end+1) = numel(scores.names); %#ok<AGROW>
        
        table_analysis_sorting = cat(2, table_analysis_sorting, scores.order);
        
        table_scores = cat(2, table_scores, scores.names);
        
        table_data = cat(2, table_data, scores.values);

        print_indent(-1);
        
    end;

    print_indent(-1);
    
    table_experiment_count(e) = sum(table_analysis_count) - k; %#ok<AGROW>
    
    list_experiments{e} = list_analysis; %#ok<AGROW>
    
end

header = cell(3, sum(table_analysis_count) + 3);

header(1, cumsum([1, table_experiment_count(1:end-1)])) = cellfun(@(x, s) create_table_cell(x.name, 'Columns', s), experiments, num2cell(table_experiment_count), 'UniformOutput', false);
header(2, cumsum([1, table_analysis_count(1:end-1)])) = cellfun(@(x, s) create_table_cell(x, 'Columns', s), table_analysis, num2cell(table_analysis_count), 'UniformOutput', false);
header(3, 1:end-3) = table_scores;

context.prefix = '';

document = document_create(context, 'index', 'title', 'Report overview');

tabledata = num2cell(table_data);

header(3, end-2:end) = {'Platform', 'Interpreter', 'Environment'};

tabledata(:, end+1) = cellfun(@get_platform, trackers, 'UniformOutput', false);
tabledata(:, end+1) = cellfun(@get_interpreter, trackers, 'UniformOutput', false);
tabledata(:, end+1) = cellfun(@get_environment, trackers, 'UniformOutput', false);

table_analysis_sorting = cat(2, table_analysis_sorting, {'none', 'none', 'none'});

tabledata = highlight_best_rows(tabledata, table_analysis_sorting);

document.table(tabledata, 'columnLabels', header, 'rowLabels', tracker_labels);

document.raw('<ul>');

for e = 1:numel(experiments)
    
    experiment = experiments{e};
    
    document.raw('<li>Experiment %s', experiment.name);
    document.raw('<ul>');
    
    analyses = convert_metadata(experiment.analysis);
    
    for a = 1:numel(analyses)
        document.raw('<li>');
        document.link(list_experiments{e}{a}.target_file, list_experiments{e}{a}.title);
        document.raw('</li>');
    end;
    
    document.raw('</ul></li>');
    
end;

document.raw('</ul>');

document.write();

end

function platform = get_platform(tracker)

    if isfield(tracker, 'metadata') && isfield(tracker.metadata, 'platform')
        platform = tracker.metadata.platform;
    else
        platform = '';
    end
end

function interpreter = get_interpreter(tracker)

    if isfield(tracker, 'interpreter')
        interpreter = tracker.interpreter;
    else
        interpreter = '';
    end
end

function envirionment = get_environment(tracker)

    if isfield(tracker.metadata, 'environment')
        envirionment = tracker.metadata.environment;
    else
        envirionment = 'unknown';
    end
end


function a = convert_metadata(a)

    if ischar(a)
        a = {struct('type', a, 'parameters', {{}})};
    elseif isstruct(a)
        a = {struct_merge(a, struct('type', '', 'parameters', {{}}))};
    else
        a = cellfun(@convert_metadata, a, 'UniformOutput', false);
        a = vertcat(a{:});
    end;

end

