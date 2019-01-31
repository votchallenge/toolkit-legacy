function initialize_native()
% initialize_native Initialize all native components
%
% A script that compiles all native components (MEX functions) and places
% them in a given output directory.
%
% Input:
% - output_path (string): Path to output directory.
%

toolkit_path = get_global_variable('toolkit_path');
output_path = get_global_variable('native_path');

trax_path = get_global_variable('trax_source', fullfile(output_path, 'trax'));
if ~download_trax_source(trax_path)
    error('Unable to compile native resources.');
end;

print_text('Verifying native components ...');

success = true;

include_paths = {fullfile(trax_path, 'src'), fullfile(trax_path, 'include')};

success = success && compile_mex('region_overlap', {fullfile(toolkit_path, 'sequence', 'region_overlap.cpp'), ...
    fullfile(trax_path, 'src', 'region.c')}, include_paths, output_path, '-DTRAX_STATIC_DEFINE');

success = success && compile_mex('region_mask', {fullfile(toolkit_path, 'sequence', 'region_mask.cpp'), ...
    fullfile(trax_path, 'src', 'region.c')}, include_paths, output_path, '-DTRAX_STATIC_DEFINE');

success = success && compile_mex('region_convert', {fullfile(toolkit_path, 'sequence', 'region_convert.cpp'), ...
    fullfile(trax_path, 'src', 'region.c')}, include_paths, output_path, '-DTRAX_STATIC_DEFINE');

success = success && compile_mex('read_trajectory', {fullfile(toolkit_path, 'sequence', 'read_trajectory.cpp'), ...
    fullfile(trax_path, 'src', 'region.c')}, include_paths, output_path, '-DTRAX_STATIC_DEFINE');

success = success && compile_mex('write_trajectory', {fullfile(toolkit_path, 'sequence', 'write_trajectory.cpp'), ...
    fullfile(trax_path, 'src', 'region.c')}, include_paths, output_path, '-DTRAX_STATIC_DEFINE');

success = success && compile_mex('benchmark_native', {fullfile(toolkit_path, 'tracker', 'benchmark_native.cpp')}, ...
    {}, output_path);

success = success && compile_mex('md5hash', {fullfile(toolkit_path, 'utilities', 'md5hash.cpp')}, ...
    {}, output_path);

trax_mex_path = fullfile(output_path, 'mex');
mkpath(trax_mex_path);

success = success && compile_mex('traxserver', ...
    {fullfile(trax_path, 'support', 'matlab', 'traxserver.cpp'), ...
     fullfile(trax_path, 'support', 'matlab', 'helpers.cpp'), ...
     fullfile(trax_path, 'src', 'trax.c'), ...
     fullfile(trax_path, 'src', 'region.c'), ...
     fullfile(trax_path, 'src', 'strmap.c'), ...
     fullfile(trax_path, 'src', 'message.c'), ...
     fullfile(trax_path, 'src', 'traxpp.cpp'), ...
     fullfile(trax_path, 'src', 'base64.c')}, ...
    {fullfile(trax_path, 'src'), fullfile(trax_path, 'include')}, trax_mex_path, '-DTRAX_STATIC_DEFINE');

% Additional OS-specific flags for traxclient MEX
os_specific = {};
if isunix() && ~ismac()
    % clock_gettime() in trax/support/client/timer.cpp requires librt on
    % linux systems with glibc < 2.17 (so to be safe, we always add it)
    os_specific{end+1} = '-lrt';
end

success = success && compile_mex('traxclient', ...
    {fullfile(trax_path, 'support', 'matlab', 'traxclient.cpp'), ...
     fullfile(trax_path, 'support', 'matlab', 'helpers.cpp'), ...
     fullfile(trax_path, 'support', 'client', 'client.cpp'), ...
     fullfile(trax_path, 'support', 'client', 'process.cpp'), ...
     fullfile(trax_path, 'support', 'client', 'threads.cpp'), ...
     fullfile(trax_path, 'support', 'client', 'timer.cpp'), ...
     fullfile(trax_path, 'src', 'trax.c'), ...
     fullfile(trax_path, 'src', 'traxpp.cpp'), ...
     fullfile(trax_path, 'src', 'region.c'), ...
     fullfile(trax_path, 'src', 'strmap.c'), ...
     fullfile(trax_path, 'src', 'message.c'), ...
     fullfile(trax_path, 'src', 'base64.c')}, ...
    {fullfile(trax_path, 'src'), ...
     fullfile(trax_path, 'include'), ...
     fullfile(trax_path, 'support', 'client', 'include'), ...
     fullfile(trax_path, 'support', 'matlab')}, output_path, '-DTRAX_STATIC_DEFINE', os_specific{:});

if ~success
    error('Unable to compile all native resources.');
end;

set_global_variable('trax_mex', trax_mex_path);

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

trax_branch = get_global_variable('trax_source_branch', 'master');

trax_url = get_global_variable('trax_url', sprintf('https://codeload.github.com/votchallenge/trax/zip/%s', trax_branch));

if isempty(trax_url)
    success = false;
    return;
end;

trax_header = fullfile(trax_dir, 'include', 'trax.h');

if ~exist(trax_header, 'file')
    print_text('Downloading TraX source from "%s". Please wait ...', trax_url);
    working_directory = tempname;
    mkdir(working_directory);
    mkdir(trax_dir);
    bundle = [tempname, '.zip'];
    try
        urlwrite(trax_url, bundle);
        unzip(bundle, working_directory);
        delete(bundle);
        copyfile(fullfile(working_directory, sprintf('trax-%s', trax_branch), '*'), trax_dir);
        success = true;
		delpath(working_directory);
    catch
        print_text('Unable to unpack TraX source code.');
        success = false;
    end;
    delpath(working_directory);
else
    print_debug('TraX source code already present.');
    success = true;
end;

if success
    if exist(fullfile(trax_dir, 'python'), 'dir') == 7
        set_global_variable('trax_python', fullfile(trax_dir, 'support', 'python'));
    end
end

end
