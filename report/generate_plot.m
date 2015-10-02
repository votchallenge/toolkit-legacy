function handle = generate_plot(varargin)
% generate_plot Generate an blank plot
%
% The function creates and configures an new plot that can be then populated.
%
% Input:
% - varargin[Title] (string): A title of the plot.
% - varargin[Visible] (boolean): Is the figure visible on the display.
% - varargin[Width] (double): Figure width hint.
% - varargin[Height] (double): Figure height hint.
% - varargin[Box] (boolean): Enable axis box
% - varargin[Grid] (boolean): Enable axis grid
% - varargin[Handle] (handle): Plot on existing figure handle.
% - varargin (other): Forward parameters to axis settings.
%
% Output:
% - handle (handle): A figure handle.
%

    plot_title = [];
    visible = false;    
    width = 4;
    height = 4;
    axis_box = true;
    axis_grid = true;
    handle = [];
    axis_settings = {};
    
    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'title'
                plot_title = varargin{i+1};
            case 'visible'
                visible = varargin{i+1};    
            case 'width'
                width = varargin{i+1};
            case 'height'
                height = varargin{i+1};
            case 'box'
                axis_box = varargin{i+1};
            case 'grid'
                axis_grid = varargin{i+1};
            case 'handle'
                handle = varargin{i+1};
            otherwise 
                axis_settings{end+1} = varargin{i}; %#ok<AGROW>
                axis_settings{end+1} = varargin{i+1}; %#ok<AGROW>
        end
    end 

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
    if axis_box
        box on; 
    end;
    if axis_grid
        grid on;
    end
    
    if ~isempty(plot_title)
        title(plot_title, 'interpreter', 'none'); 
    end;
    
    if ~isempty(axis_settings)
        set(gca, axis_settings{:});
    end;
    
    set(handle, 'PaperUnits', 'inches', 'PaperSize', [width, height], 'PaperPosition', [0, 0, width, height]);

    hold off;
    
end
