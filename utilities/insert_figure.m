function insert_figure(context, fid, handle, id, title)

    fprintf(fid, '<div class="plot">\n');

    export_figure(handle, fullfile(context.images, [context.prefix, id]), 'png', 'cache', context.cache);

    fprintf(fid, ...
        '<img src="%s/%s%s.png" alt="%s" /><span class="caption">%s</span>\n', ...
        context.imagesurl, context.prefix, id, title, title);

    if context.exportlatex

            export_figure(handle, fullfile(context.images, [context.prefix, id]), 'eps', 'cache', context.cache);
            
            fprintf(fid, '<a href="%s/%s%s.eps" class="export eps">EPS</a>', ...
                context.imagesurl, context.prefix, id);

    end;


    if context.exportraw
            
            file = export_figure(handle, fullfile(context.data, [context.prefix, id]), 'fig', 'cache', context.cache);
            
            % Hack : try to fix potential figure invisibility
            try
                f = load(file, '-mat');
                n = fieldnames(f);
                f.(n{1}).properties.Visible = 'on';
                save(file, '-struct', 'f'); 
            catch e
                print_debug('Warning: unable to fix figure visibility: %s', e.message);
            end;

            fprintf(fid, '<a href="%s/%s%s.fig" class="export eps">FIG</a>', ...
                context.imagesurl, context.prefix, id);
    end;

    fprintf(fid, '</div>\n');

