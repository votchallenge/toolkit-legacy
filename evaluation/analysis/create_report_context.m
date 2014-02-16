function context = create_report_context(name)

context.root = fullfile(get_global_variable('directory'), 'reports', name);
context.images = fullfile(context.root, 'images');
context.data = fullfile(context.root, 'data');
context.prefix = '';
context.imagesurl = 'images';

mkpath(context.root);
mkpath(context.images);
mkpath(context.data);