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
        set(gca, 'FontSize', 12, 'FontWeight', 'bold', 'linewidth', 2);
        print( handle, '-depsc', [filename, '.eps']);
    case 'png'
        print( handle, '-dpng', '-r130', [filename, '.png']);
    otherwise
        error('Unknown format');
end;
