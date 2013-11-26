function hf = generate_permutation_plot(ranks, criteria, plot_labels, plot_style, varargin)

    plot_title = [];
    normalized = 0;
    width = 9;
    height = 3;
    
    
    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'title'
                plot_title = varargin{i+1}; 
            case 'normalized'
                normalized = varargin{i+1};      
            case 'width'
                width = varargin{i+1};
            case 'height'
                height = varargin{i+1};                        
            otherwise 
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end 

    hf = figure('Visible', 'off');

    [~, I] = sort(ranks, 2, 'ascend');

    hold on; grid on; box on;

    if ~normalized
    
        for t = 1:length(plot_labels)

            x = ranks(:, t);

            plot(x, 1:length(criteria), [plot_style{1, t}, '--'], ...
                'Color', plot_style{2, t}, 'MarkerSize', 10,  'LineWidth', plot_style{3, t});

        end;

        if ~isempty(plot_title)
            title(plot_title,'interpreter','none');
        end;
    else
       
        for t = 1:length(plot_labels)

            x = mod(find(I' == t)-1, length(plot_labels))+1;

            plot(x, 1:length(criteria), [plot_style{1, t}, '--'], ...
                'Color', plot_style{2, t}, 'MarkerSize', 10,  'LineWidth', plot_style{3, t});

        end;

        if ~isempty(plot_title)
            title([plot_title, '(normalized)'],'interpreter','none');
        end;
    end;
    legend(plot_labels, 'Location', 'NorthEastOutside'); 
    xlabel('Rank'); 

    set(gca,'ytick', 1:numel(criteria),'yticklabel', criteria, 'YDir','Reverse');
    set(gca,'xtick', 1:length(plot_labels), 'xlim', [0.9, length(plot_labels)+0.1]);

    hold off;
    
    set(hf, 'PaperUnits', 'inches', 'PaperSize', [width, height], 'PaperPosition', [0, 0, width, height])

    