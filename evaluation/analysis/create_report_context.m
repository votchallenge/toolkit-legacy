function context = create_report_context(parent)

context.root = parent;
context.images = fullfile(context.root, 'images');
context.data = fullfile(context.root, 'data');
context.prefix = '';
context.imagesurl = 'images';

mkpath(context.root);
mkpath(context.images);
mkpath(context.data);