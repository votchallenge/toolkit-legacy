function handle = generate_trackers_legend(trackers, varargin)
% generate_ar_plot Generate a tracker legend plot
%
% The function generates dedicated tracker legend plot. Tracker labels and
% their symbols are ordered in a grid.
%
% Input:
% - trackers (cell): A cell array of tracker structures.
% - varargin[Visible] (boolean): Is the figure visible on the display.
% - varargin[Width] (double): Figure width hint.
% - varargin[Height] (double): Figure height hint.
% - varargin[Rows] (integer): Number of rows in a grid.
% - varargin[Columns] (integer): Number of columns in a grid.
% - varargin[Handle] (handle): Plot on existing figure handle.
%
% Output:
% - handle (handle): A figure handle.
%

    width = [];
    height = [];
    handle = [];
    sorted = false;
    
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
            case 'sorted'
                sorted = varargin{i+1};
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

    if sorted
        labels = cellfun(@(x) lower(x.label), trackers, 'UniformOutput', false);
        [~, order] = sort(labels);
        trackers = trackers(order);
    end
    
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

        text(X(t) + 0.2, Y(t), trackers{t}.label, args{:});

    end;

    limits = [0.9, 0.5, width+1.1, height+0.5];

    xlim([0.9, columns+1.1]);
    ylim([0.5, rows+0.5]);

	set(gca,'YDir','reverse');
    box off; grid off; axis off;

    set(handle, 'PaperUnits', 'inches', 'PaperSize', [width, height], 'PaperPosition', limits);

    hold off;
