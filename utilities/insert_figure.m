function insert_figure(context, fid, hf, id, title, varargin)

format = 'html';
cache = true;

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'format'
            format = varargin{i+1};
        case 'cache'
            cache = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

switch lower(format)
    case 'html'
        export_figure(hf, fullfile(context.images, [context.prefix, id]), 'png', 'cache', cache);

        fprintf(fid, ...
            '<p class="plot"><img src="%s/%s%s.png" alt="%s" /><span class="caption">%s</span></p>\n', ...
            context.imagesurl, context.prefix, id, title, title);
    case 'latex'
        export_figure(hf, fullfile(context.images, [context.prefix, id]), 'eps', 'cache', cache);
        
        fprintf(fid, ...
            '\\begin{figure}\\centering\\includegraphics{%s/%s%s.eps}\\caption{%s}\\end{figure}\n', ...
            context.imagesurl, context.prefix, id, title);        
        
    case 'data'
        
        file = export_figure(hf, fullfile(context.data, [context.prefix, id]), 'fig', 'cache', cache);
        
        % Hack : try to fix potential figure invisibility
        try
            f=load(file,'-mat');
            n=fieldnames(f);
            f.(n{1}).properties.Visible='on';
            save(file,'-struct','f'); 
        catch e
            print_debug('Warning: unable to fix figure visibility: %s', e.message);
        end;
end;