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
        
        export_figure(hf, fullfile(context.data, [context.prefix, id]), 'fig');
end;