function compile_all_native(output_path)

toolkit_path = get_global_variable('toolkit_path');

trax_path = get_global_variable('trax_source', fullfile(toolkit_path, 'trax'));

if ~get_trax_source(trax_path)
    error('Unable to compile all native resources.');
end;

print_text('Compiling MEX files ...');

success = true;

success = success && compile_mex('region_overlap', {fullfile(toolkit_path, 'measures', 'region_overlap.cpp'), ...
    fullfile(trax_path, 'lib', 'region.c')}, {fullfile(trax_path, 'lib')}, output_path);

success = success && compile_mex('region_mask', {fullfile(toolkit_path, 'sequence', 'region_mask.cpp'), ...
    fullfile(trax_path, 'lib', 'region.c')}, {fullfile(trax_path, 'lib')}, output_path);

success = success && compile_mex('region_convert', {fullfile(toolkit_path, 'sequence', 'region_convert.cpp'), ...
    fullfile(trax_path, 'lib', 'region.c')}, {fullfile(trax_path, 'lib')}, output_path);

success = success && compile_mex('read_trajectory', {fullfile(toolkit_path, 'sequence', 'read_trajectory.cpp'), ...
    fullfile(trax_path, 'lib', 'region.c')}, {fullfile(trax_path, 'lib')}, output_path);

success = success && compile_mex('write_trajectory', {fullfile(toolkit_path, 'sequence', 'write_trajectory.cpp'), ...
    fullfile(trax_path, 'lib', 'region.c')}, {fullfile(trax_path, 'lib')}, output_path);

success = success && compile_mex('benchmark_native', {fullfile(toolkit_path, 'measures', 'benchmark_native.cpp')}, ...
    {}, output_path);

success = success && compile_mex('md5hash', {fullfile(toolkit_path, 'utilities', 'md5hash.cpp')}, ...
    {}, output_path);

if ~success
    error('Unable to compile all native resources.');
end;

end


function [success] = get_trax_source(trax_path)

trax_url = 'https://github.com/lukacu/trax/archive/master.zip';

trax_header = fullfile(trax_path, 'lib', 'trax.h');

if ~exist(trax_header, 'file')
    print_text('Downloading TraX source from "%s". Please wait ...', trax_url);
    working_directory = tempname;
    mkdir(working_directory);
    bundle = [tempname, '.zip'];
    try
        urlwrite(trax_url, bundle);
        unzip(bundle, working_directory);
		delete(bundle);
        movefile(fullfile(working_directory, 'trax-master'), trax_path);
        success = true;
    catch
        print_text('Unable to retrieve TraX source code.');
        success = false;
    end;
    recursive_rmdir(working_directory);
else
    print_debug('TraX source code already present.');
    success = true;
end;





end
