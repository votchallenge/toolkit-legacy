function fullpath = export_figure(handle, filename, format, varargin)

cache = false;

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'cache'
            cache = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

fullpath = [filename, '.', format];

if cache && exist(fullpath, 'file') 
    return;
end;

if ~isnumeric(handle)
   handle = handle(); 
end

switch lower(format)
    case 'fig'
        saveas(handle, filename, 'fig');
    case 'eps'
        fontSize = get(gca, 'FontSize');
        fontWeight = get(gca, 'FontWeight');
        lineWidth = get(gca, 'LineWidth');
        set(gca, 'FontSize', 10, 'FontWeight', 'bold', 'LineWidth', 2);
        print( handle, '-depsc', [filename, '.eps']);
        set(gca, 'FontSize', fontSize, 'FontWeight', fontWeight, 'LineWidth', lineWidth);
    case 'png'
        print( handle, '-dpng', '-r130', [filename, '.png']);
    otherwise
        error('Unknown format');
end;
