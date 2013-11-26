function export_figure(handle, filename, format)

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
