function compile_all_native()

toolkit_path = get_global_variable('toolkit_path');

trax_path = fullfile(toolkit_path, 'trax');

print_text('Compiling MEX files ...');

compile_mex('coverlap', {fullfile(toolkit_path, 'measures', 'coverlap.cpp'), ...
    fullfile(trax_path, 'native', 'region.c')}, {fullfile(trax_path, 'native')});

compile_mex('read_trajectory', {fullfile(toolkit_path, 'sequence', 'read_trajectory.cpp'), ...
    fullfile(trax_path, 'native', 'region.c')}, {fullfile(trax_path, 'native')});

compile_mex('write_trajectory', {fullfile(toolkit_path, 'sequence', 'write_trajectory.cpp'), ...
    fullfile(trax_path, 'native', 'region.c')}, {fullfile(trax_path, 'native')});