function fullpath = export_figure(handle, filename, format, varargin)
% export_figure Export a figure to various formats
%
% Utility function that exports a figure to various formats taking care
% of caching as well as some other options.
%
% Input:
% - handle (handle): Handle of a figure.
% - filename (string): Filename of the target file without extension.
% - format (string): Target format (fig, eps or png).
% - varargin[Cache] (boolean): Use caching. Disabled by default.
%
% Output:
% - fullpath (string): Path to the resulting file.
%


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

if isa(handle, 'function_handle')
    autoclose = true;
    cache = true;
else
    autoclose = false;
end

if cache && exist(fullpath, 'file') 
    return;
end;

if isa(handle, 'function_handle')
    handle = handle();
end;

switch lower(format)
    case 'fig'
        saveas(handle, filename, 'fig');
    case 'eps'
        allca = num2cell(findall(handle, 'type', 'axes'));
        allbackup = cellfun(@update_axis, allca, 'UniformOutput', false);
        print( handle, '-depsc', [filename, '.eps']);
        cellfun(@restore_axis, allca, allbackup, 'UniformOutput', false);
    case 'png'
        ah = get(handle, 'CurrentAxes');
        title = get(ah, 'Title');
        set(title, 'Visible', 'off');
        print( handle, '-dpng', '-r130', [filename, '.png']);
        set(title, 'Visible', 'on');
    otherwise
        error('Unknown format');
end;

if autoclose
    close(handle);
end

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
