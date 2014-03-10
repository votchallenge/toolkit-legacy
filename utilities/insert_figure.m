function insert_figure(context, fid, hf, id, title, varargin)

format = 'html';

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'format'
            format = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

switch lower(format)
    case 'html'
        export_figure(hf, fullfile(context.images, [context.prefix, id]), 'png');

        fprintf(fid, ...
            '<p class="plot"><img src="%s/%s%s.png" alt="%s" /><span class="caption">%s</span></p>\n', ...
            context.imagesurl, context.prefix, id, title, title);
    case 'data'
        
        file = export_figure(hf, fullfile(context.data, [context.prefix, id]), 'fig');
        
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