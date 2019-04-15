
tracker_label = 'Demo_py';

% Note: be carefull for double backslashes on Windows
tracker_command = generate_python_command('python_static_rgbd', ...
    {'<path-to-toolkit-dir>\\tracker\\examples\\python', ...  % tracker source and vot.py are here
    '<path-to-trax-dir>\\support\\python'});

tracker_interpreter = 'python';

tracker_linkpath = {'<path-to-trax-build-dir>\bin', ...
    '<path-to-trax-build-dir>\lib'};
