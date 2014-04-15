function output_path = compile_all_native()

toolkit_path = get_global_variable('toolkit_path');

output_path = fullfile(toolkit_path, 'mex');

mkpath(output_path);

trax_path = get_global_variable('trax_source', fullfile(toolkit_path, 'trax'));

print_text('Compiling MEX files ...');

success = true;

success = success && compile_mex('coverlap', {fullfile(toolkit_path, 'measures', 'coverlap.cpp'), ...
    fullfile(trax_path, 'lib', 'region.c')}, {fullfile(trax_path, 'lib')}, output_path);

success = success && compile_mex('read_trajectory', {fullfile(toolkit_path, 'sequence', 'read_trajectory.cpp'), ...
    fullfile(trax_path, 'lib', 'region.c')}, {fullfile(trax_path, 'lib')}, output_path);

success = success && compile_mex('write_trajectory', {fullfile(toolkit_path, 'sequence', 'write_trajectory.cpp'), ...
    fullfile(trax_path, 'lib', 'region.c')}, {fullfile(trax_path, 'lib')}, output_path);

success = success && compile_mex('benchmark_native', {fullfile(toolkit_path, 'measures', 'benchmark_native.cpp')}, ...
    {}, output_path);

if ~success
    error('Unable to compile all native resources.');
end;