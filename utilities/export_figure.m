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
        allca = num2cell(findall(handle, 'type', 'axes'));
        allbackup = cellfun(@update_axis, allca, 'UniformOutput', false);
        print( handle, '-depsc', [filename, '.eps']);
        cellfun(@restore_axis, allca, allbackup, 'UniformOutput', false);
    case 'png'
        print( handle, '-dpng', '-r130', [filename, '.png']);
    otherwise
        error('Unknown format');
end;

end

function [backup] = update_axis(ha)
    backup.fontSize = get(ha, 'FontSize');
    backup.fontWeight = get(ha, 'FontWeight');
    backup.lineWidth = get(ha, 'LineWidth');
    set(ha, 'FontSize', 10, 'FontWeight', 'bold', 'LineWidth', 2);
end
 
function [backup] = restore_axis(ha, backup)
    set(ha, 'FontSize', backup.fontSize, 'FontWeight', backup.fontWeight, 'LineWidth', backup.lineWidth);
end