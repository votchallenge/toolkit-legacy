function initialize_native(output_path)
% initialize_native Initialize all native components
%
% A script that downloads or compiles all native components (MEX functions) and places
% them in a given output directory.
%
% Input:
% - output_path (string): Path to output directory.
%

toolkit_path = get_global_variable('toolkit_path');

% First attempt to download precompiled binaries
if get_global_variable('native_download', true) && download_native(output_path)
    return;
end;

print_text('');
print_text('***************************************************************************');
print_text('');
print_text('Warning: The toolkit was unable to download precompiled native components.');
print_text('It will not attempt to compile them from source, however, some components');
print_text('have to be compiled manually. Consult the documentation for more information.');
print_text('');
print_text('***************************************************************************');
print_text('');

trax_path = get_global_variable('trax_source', fullfile(output_path, 'trax'));
if ~download_trax_source(trax_path)
    error('Unable to compile all native resources.');
end;

print_text('Compiling native files ...');

success = true;

success = success && compile_mex('region_overlap', {fullfile(toolkit_path, 'sequence', 'region_overlap.cpp'), ...
    fullfile(trax_path, 'lib', 'region.c')}, {fullfile(trax_path, 'lib')}, output_path);

success = success && compile_mex('region_mask', {fullfile(toolkit_path, 'sequence', 'region_mask.cpp'), ...
    fullfile(trax_path, 'lib', 'region.c')}, {fullfile(trax_path, 'lib')}, output_path);

success = success && compile_mex('region_convert', {fullfile(toolkit_path, 'sequence', 'region_convert.cpp'), ...
    fullfile(trax_path, 'lib', 'region.c')}, {fullfile(trax_path, 'lib')}, output_path);

success = success && compile_mex('read_trajectory', {fullfile(toolkit_path, 'sequence', 'read_trajectory.cpp'), ...
    fullfile(trax_path, 'lib', 'region.c')}, {fullfile(trax_path, 'lib')}, output_path);

success = success && compile_mex('write_trajectory', {fullfile(toolkit_path, 'sequence', 'write_trajectory.cpp'), ...
    fullfile(trax_path, 'lib', 'region.c')}, {fullfile(trax_path, 'lib')}, output_path);

success = success && compile_mex('benchmark_native', {fullfile(toolkit_path, 'tracker', 'benchmark_native.cpp')}, ...
    {}, output_path);

success = success && compile_mex('md5hash', {fullfile(toolkit_path, 'utilities', 'md5hash.cpp')}, ...
    {}, output_path);

if ~success
    error('Unable to compile all native resources.');
end;

end

function success = download_native(native_dir)
% download_trax_source Download external components from TraX repository.
%
% To reduce redundant code, a part of the source for MEX files is provided
% by the TraX library. This function downloads and unpacks the source of
% the library and places it in a desired directory.
%
% Input:
% - trax_path (string): Path to the destination directory.
%
% Output:
% - success (boolean): True on success.
%

success = false;

if ~(exist(fullfile(native_dir, 'trax.h'), 'file') == 2)

    if ispc()
        ostype = 'windows';
    elseif ismac()
        ostype = 'mac';
    else
        ostype = 'linux';
    end

    if ~isempty(strfind(computer('arch'), '64'))
        arch = '64';
    else
        arch = '32';
    end;

    tempdir = tempname;
    mkdir(tempdir);

    native_url = get_global_variable('native_url', 'http://box.vicos.si/vot/toolkit/');

    vot_bundle_url = sprintf('%svot-%s%s.zip', native_url, ostype, arch);
    trax_bundle_url = sprintf('%strax-%s%s.zip', native_url, ostype, arch);

    try 
        print_debug('Downloading from %s.', vot_bundle_url);
        urlwrite(vot_bundle_url, fullfile(tempdir, 'vot.zip'));
        print_debug('Downloading from %s.', trax_bundle_url);
        urlwrite(trax_bundle_url, fullfile(tempdir, 'trax.zip'));
    catch
        return;
    end

    print_text('Downloaded native file bundles.');

    unzip(fullfile(tempdir, 'vot.zip'), native_dir);
    delete(fullfile(tempdir, 'vot.zip'));

    unzip(fullfile(tempdir, 'trax.zip'), native_dir);
    delete(fullfile(tempdir, 'trax.zip'));

    rmpath(tempdir);

end;

if exist(fullfile(native_dir, iff(ispc(), 'traxclient.exe', 'traxclient')), 'file') == 2
    set_global_variable('trax_client', fullfile(native_dir, iff(ispc(), 'traxclient.exe', 'traxclient')));
end

if exist(fullfile(native_dir, 'mex', ['traxserver.', mexext]), 'file') == 2
    set_global_variable('trax_mex', fullfile(native_dir, 'mex'));
end

success = true;

end

function success = download_trax_source(trax_dir)
% download_trax_source Download external components from TraX repository.
%
% To reduce redundant code, a part of the source for MEX files is provided
% by the TraX library. This function downloads and unpacks the source of
% the library and places it in a desired directory.
%
% Input:
% - trax_dir (string): Path to the destination directory.
%
% Output:
% - success (boolean): True on success.
%

trax_url = get_global_variable('trax_url');

if isempty(trax_url)
    success = false;
    return;
end;

trax_header = fullfile(trax_dir, 'lib', 'trax.h');

if ~exist(trax_header, 'file')
    print_text('Downloading TraX source from "%s". Please wait ...', trax_url);
    working_directory = tempname;
    mkdir(working_directory);
    bundle = [tempname, '.zip'];
    try
        urlwrite(trax_url, bundle);
        unzip(bundle, working_directory);
		delete(bundle);
        movefile(fullfile(working_directory, 'trax-master'), trax_dir);
        success = true;
    catch
        print_text('Unable to retrieve TraX source code.');
        success = false;
    end;
    rmpath(working_directory);
else
    print_debug('TraX source code already present.');
    success = true;
end;

end
