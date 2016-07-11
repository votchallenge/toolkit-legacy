function report_visualization(context, experiments, trackers, sequences, varargin)
% report_visualization Basic visualization of performance for given trackers
%
% This function generates images with tracking results of given trackers along with a 
% performance scores. This can be used to examine tracker failures or to
% visually compare multiple trackers.
%
% Input:
% - context (structure): Report context structure.
% - trackers (struct): An array of tracker structures.
% - experiments (cell): An array of experiment structures.
% - sequences (cell): An array of sequence structures.
%
% Output:
% - images in output directory defined in context.root

measures_labels = {'Overlap', 'Failures', 'Speed'};
context.measures = {@(trajectory, sequence, experiment, tracker) ...
    estimate_accuracy(trajectory, sequence, 'burnin', experiment.parameters.burnin), ...
    @(trajectory, sequence, experiment, tracker) estimate_failures(trajectory, sequence), ...
    @estimate_speed};

if ~iscell(trackers)
    trackers = {trackers};
end;

results.trackers_scores = cell(numel(trackers), 1);
results.trackers_trajectories = cell(numel(trackers), 1);

for t = 1:numel(trackers)
    tracker = trackers{t};
    
    context.sequences = sequences;
    context.scores = cell(numel(experiments), 1);
    context.scores_frames = cell(numel(experiments), 1);
    context.trajectories = cell(numel(experiments), 1);
    
    context = iterate(experiments, tracker, sequences, 'iterator', @evaluate_iterator, 'context', context);

    results.trackers_scores{t} = context.scores_frames;
    results.trackers_trajectories{t} = context.trajectories;
end;

print_text('Creating images ... this may take a while!');

[trackers_styled] = set_trackers_visual_identity(trackers);

% make tracker markers thicker
for t = 1:numel(trackers)
    trackers_styled{t}.style.width = 3;
end

index_score_acc = 1;
index_score_rob = 2;
index_score_speed = 3;

gt_style.color = [1, 1, 1];
gt_style.symbol = '.';
gt_style.font_color = [0.01, 0.01, 0.01];
gt_style.width = 3;

print_indent(1);

for i = 1:numel(sequences)
    
    print_text('Sequence %s', sequences{i}.name);
    
    for e = 1:numel(experiments)
        seq_directory = fullfile(context.root, experiments{e}.name, sequences{i}.name);
        mkpath(seq_directory);
        
        image_width = max([sequences{i}.width 480]);
        image_height = max([sequences{i}.height   sequences{i}.height*image_width/sequences{i}.width]);
        
        for f = 1:sequences{i}.length
            
            image_handle = figure('Visible', 'off');
            imshow(imread(get_image(sequences{i}, f)));
            hold on;
            for t = 1:numel(trackers)
                valid = plot_polygon(results.trackers_trajectories{t}{e}{i}{f}, trackers_styled{t}.style);

                if f <=  experiments{e}.parameters.burnin
                    acc = -1;
                else
                    acc = results.trackers_scores{t}{e}{i, index_score_acc}(f);
                    if isnan(acc) acc = 0; end
                end
                
                acc_avg = nanmean(results.trackers_scores{t}{e}{i, index_score_acc}(1:f));
                if isnan(acc_avg)
                    acc_avg = 0;
                end
                
                if valid || f == 1
                    trackers_styled{t}.label = sprintf('%s (%.02f), total(%d, %.02f)', trackers{t}.label, ...
                        acc, sum(results.trackers_scores{t}{e}{i, index_score_rob}(:) <= f), ...
                        acc_avg);
                    trackers_styled{t}.style.font_color = [0, 0, 0];
                    trackers_styled{t}.style.font_bold = false;
                else
                    trackers_styled{t}.label = sprintf('%s (0.00), total(%d, %.02f)', trackers{t}.label, ...
                        sum(results.trackers_scores{t}{e}{i, index_score_rob}(:) <= f), acc_avg);
                    trackers_styled{t}.style.font_color = [0.77, 0, 0];
                    trackers_styled{t}.style.font_bold = true;
                end
                
            end
            
            plot_polygon(sequences{i}.groundtruth{f}, gt_style);
            hold off;
            set(image_handle, 'PaperUnits', 'inches', 'PaperPosition', [0 0 image_width/75, image_height/75], 'PaperSize', [image_width/75 image_height/75]);
            
            legend_handle = generate_tracker_legend_stats(trackers_styled, 'visible', false, 'columns', 2, 'rows', ceil(numel(trackers)/2), 'width', image_width/75);
            
            print( image_handle, '-djpeg', '-r75', [fullfile(seq_directory, sprintf('%08d-img', f)), '.jpg']);
            print( legend_handle, '-djpeg', '-r75', [fullfile(seq_directory, sprintf('%08d-legend', f)), '.jpg']);
            
            
            %montage_command = sprintf('montage -tile 1x2 -geometry +0+1 "%s" "%s" "%s"; rm %s; rm %s', ...
            %                    fullfile(seq_directory, sprintf('%08d-img.jpg', f)), ...
            %                    fullfile(seq_directory, sprintf('%08d-legend.jpg', f)), ...
            %                    fullfile(seq_directory, sprintf('%08d.jpg', f)), ...
            %                    fullfile(seq_directory, sprintf('%08d-img.jpg', f)), ...
            %                    fullfile(seq_directory, sprintf('%08d-legend.jpg', f)));
            %system(montage_command);
            
            close(image_handle);
            close(legend_handle);
        end

       
    end
end

print_indent(-1);

end

function context = evaluate_iterator(event, context)

switch (event.type)
    case 'experiment_enter'
        
        print_text('Experiment %s', event.experiment.name);
        
        switch event.experiment.type
            case 'supervised'
                defaults = struct('repetitions', 15, 'skip_labels', {{}}, 'skip_initialize', 0, 'failure_overlap',  -1);
                context.experiment_parameters = struct_merge(event.experiment.parameters, defaults);
                context.scores{event.experiment_index} = nan(numel(context.sequences), numel(context.measures));
                context.scores_frames{event.experiment_index} = cell(numel(context.sequences), numel(context.measures));
                context.trajectories{event.experiment_index} = cell(numel(context.sequences), 1);
            otherwise, error(['unrecognized type ' type]);
        end
        
        print_indent(1);
    case 'experiment_exit'
        
        print_indent(-1);
        
    case 'tracker_enter'
        
        print_text('Tracker %s', event.tracker.label);
        print_indent(1);
        
    case 'tracker_exit'
        
        print_indent(-1);
        
    case 'sequence_enter'
        
        print_text('Sequence %s', event.sequence.name);
        
        sequence_directory = fullfile(event.tracker.directory, event.experiment.name, ...
            event.sequence.name);
        
        switch event.experiment.type
            case {'supervised', 'unsupervised'}
                
                scores = nan(context.experiment_parameters.repetitions, numel(context.measures));
                
                % Take only the first results files (assuming deterministic behaviour)
                for i = 1:1 %context.experiment_parameters.repetitions
                    
                    result_file = fullfile(sequence_directory, sprintf('%s_%03d.txt', event.sequence.name, i));
                    
                    if ~exist(result_file, 'file')
                        continue;
                    end;
                    
                    if i == 4 && is_deterministic(event.sequence, 3, sequence_directory)
                        print_debug('Detected a deterministic tracker, skipping remaining trials.');
                        break;
                    end;
                    
                    context.trajectories{event.experiment_index}{event.sequence_index} = read_trajectory(result_file);
                    
                    for m = 1:numel(context.measures)
                        [scores(i, m), context.scores_frames{event.experiment_index}{event.sequence_index, m}] = context.measures{m}(context.trajectories{event.experiment_index}{event.sequence_index}, event.sequence, event.experiment, event.tracker);
                    end;
                    
                end;
                
                context.scores{event.experiment_index}(event.sequence_index, :) = nanmean(scores, 1);
                
            otherwise, error(['unrecognized type ' type]);
        end
        
end;

end

function [speed, times] = estimate_speed(trajectory, sequence, experiment, tracker)

directory = fullfile(tracker.directory, experiment.name, ...
    sequence.name);

times_file = fullfile(directory, sprintf('%s_time.txt', sequence.name));

times = csvread(times_file);

speed = 1 / nanmean(times(:), 1);

times = nanmean(times, 2);

end

function valid = plot_polygon(tracker_polygon, style)

valid = true;

if numel(tracker_polygon) < 4
    valid = false;
    return;
end

if numel(tracker_polygon) == 4
    rectangle('Position',tracker_polygon, 'LineWidth', 2, 'EdgeColor', style.color);
    plot(tracker_polygon(1) + tracker_polygon(3)/2, tracker_polygon(2) + tracker_polygon(4)/2, ... 
        style.symbol, 'Color', style.color, 'MarkerSize', 15, 'LineWidth', style.width);
else
    for i = 3:2:numel(tracker_polygon)
        line([tracker_polygon(i-2)  tracker_polygon(i)], [tracker_polygon(i-1)  tracker_polygon(i+1)], ...
                'LineWidth', 2, 'Color', style.color);
    end
    line([tracker_polygon(numel(tracker_polygon)-1)  tracker_polygon(1)], [tracker_polygon(numel(tracker_polygon))  tracker_polygon(2)], ...
            'LineWidth', 2, 'Color', style.color);

    cog = [sum(tracker_polygon(1:2:end)) sum(tracker_polygon(2:2:end))] / (numel(tracker_polygon)/2);

    plot(cog(1), cog(2), style.symbol, 'Color', style.color, 'MarkerSize', 15, 'LineWidth', style.width);
end
    
end


function handle = generate_tracker_legend_stats(trackers, varargin)

    width = [];
    height = [];
    handle = [];
    
    columns = 1;
    rows = numel(trackers); 
    visible = false;

    for i = 1:2:length(varargin)
        switch lower(varargin{i})   
            case 'width'
                width = varargin{i+1};
            case 'height'
                height = varargin{i+1};
            case 'visible'
                visible = varargin{i+1};                
            case 'handle'
                handle = varargin{i+1};
            case 'columns'
                columns = varargin{i+1};
            case 'rows'
                rows = varargin{i+1};
            otherwise 
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end 

    if isempty(width)
        width = columns;
    end
    
    if isempty(height)
        height = rows / 10;
    end
    
    [Y, X] = meshgrid(1:rows, 1:columns);
   
    if isempty(handle)
        if ~visible
            handle = figure('Visible', 'off');
        else
            handle = figure();
        end
    else
        figure(handle);
    end;

    hold on; 

    for t = 1:length(trackers)

        plot(X(t), Y(t), trackers{t}.style.symbol, 'Color', ...
            trackers{t}.style.color, 'MarkerSize', 10,  'LineWidth', trackers{t}.style.width);

        if isfield(trackers{t}.style, 'font_color')
            font_color = trackers{t}.style.font_color;
        else
            font_color = [0, 0, 0];
        end;
        
        if isfield(trackers{t}.style, 'font_bold')
            font_bold = trackers{t}.style.font_bold;
        else
            font_bold = false;
        end;
        
        args = {'Interpreter', 'none', 'Color', font_color};
        
        if font_bold
           args(end+1:end+2) = {'FontWeight', 'bold'};
        end

        text(X(t) + 0.1, Y(t), trackers{t}.label, args{:});

    end;

    limits = [0, 0, width, height+0.5];

    xlim([0.9, columns+1.1]);
    ylim([0.5, rows+0.1]);

	set(gca,'YDir','reverse');
    box off; grid off; axis off;

    set(handle, 'PaperUnits', 'inches', 'PaperSize', [width, height], 'PaperPosition', limits);

    hold off;
end


