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

success = success && compile_mex('ndhistc', {fullfile(toolkit_path, 'utilities', 'ndhistc.c')}, ...
    {}, output_path);

trax_mex_path = fullfile(output_path, 'mex');
mkpath(trax_mex_path);

success = success && compile_mex('traxserver', {fullfile(trax_path, 'matlab', 'traxserver.cpp'), ...
    fullfile(trax_path, 'lib', 'trax.c'), fullfile(trax_path, 'lib', 'region.c'), fullfile(trax_path, 'lib', 'strmap.c'), ...
    fullfile(trax_path, 'lib', 'message.c'), fullfile(trax_path, 'lib', 'base64.c')}, ...
    {fullfile(trax_path, 'lib')}, trax_mex_path);

if ~success
    error('Unable to compile all native resources.');
end;

set_global_variable('trax_mex', trax_mex_path);

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

timestamp_file = fullfile(native_dir, 'timestamp.txt');

update_interval = get_global_variable('native_update_interval', 0.1);

current_timestamp = datenum(clock());
previous_timestamp = 0;

fd = fopen(timestamp_file, 'r');
if fd > 0
    previous_timestamp = fscanf(fd, '%f');
    fclose(fd);
end

if current_timestamp > previous_timestamp + update_interval

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

    native_url = get_global_variable('native_url', 'http://box.vicos.si/vot/toolkit/');
    tempdir = tempname;

    version = toolkit_version();

    try 
        snapshot = [urlread(sprintf('%srelease_%d_%d.id', native_url, version.major, version.minor)), '/'];
    catch 
        % legacy builds
        snapshot = '';
    end

    snapshot = strtrim(snapshot); % Remove trailing whitespace/newline

    trax_hash_url = sprintf('%s%strax-%s%s.md5', native_url, snapshot, ostype, arch);
    trax_bundle_url = sprintf('%s%strax-%s%s.zip', native_url, snapshot, ostype, arch);
    trax_hash_file = fullfile(native_dir, 'trax.md5');

    vot_hash_url = sprintf('%s%svot-%s%s.md5', native_url, snapshot, ostype, arch);
    vot_bundle_url = sprintf('%s%svot-%s%s.zip', native_url, snapshot, ostype, arch);
    vot_hash_file = fullfile(native_dir, 'vot.md5');

    if exist(trax_hash_file, 'file') == 2
      trax_hash = fileread(trax_hash_file);
    else
      trax_hash = '';
    end;

    % Remove the native directory from the path
    if exist('read_trajectory', 'file') == 3
        rmpath(native_dir);
    end

    updated = true;

    try 
        
        remote_hash = urlread(trax_hash_url);
        if ~strcmp(trax_hash, remote_hash)

            mkpath(tempdir);
            
            try 
                print_debug('Downloading from %s.', trax_bundle_url);
                urlwrite(trax_bundle_url, fullfile(tempdir, 'trax.zip'));
                unzip(fullfile(tempdir, 'trax.zip'), native_dir);
                delete(fullfile(tempdir, 'trax.zip'));
                fd = fopen(trax_hash_file, 'w'); fprintf(fd, '%s', remote_hash); fclose(fd);
            catch
                print_debug('Error downloading %s.', trax_bundle_url);
                updated = false;
            end
            
        end;

        set_global_variable('native_component_trax', remote_hash(remote_hash ~= sprintf('\n')));

    catch
        print_debug('Error downloading %s.', trax_hash_url);
        updated = false;
    end

    if exist(vot_hash_file, 'file') == 2
      vot_hash = fileread(vot_hash_file);
    else
      vot_hash = '';
    end;

    try 
        
        remote_hash = urlread(vot_hash_url);
        if ~strcmp(vot_hash, remote_hash)

            mkpath(tempdir);
            
            try 
                print_debug('Downloading from %s.', vot_bundle_url);
                urlwrite(vot_bundle_url, fullfile(tempdir, 'vot.zip'));
                unzip(fullfile(tempdir, 'vot.zip'), native_dir);
                delete(fullfile(tempdir, 'vot.zip'));
                fd = fopen(vot_hash_file, 'w'); fprintf(fd, '%s', remote_hash); fclose(fd);
            catch
                print_debug('Error downloading %s.', vot_bundle_url);
                updated = false;
            end

        end;

        set_global_variable('native_component_vot', remote_hash(remote_hash ~= sprintf('\n')));

    catch
        print_debug('Error downloading %s.', vot_hash_url);
        updated = false;
    end

    delpath(tempdir);

    rehash;

    if updated
        fd = fopen(timestamp_file, 'w'); fprintf(fd, '%f', current_timestamp); fclose(fd);
    end;
end;


if exist(fullfile(native_dir, iff(ispc(), 'traxclient.exe', 'traxclient')), 'file') == 2
    set_global_variable('trax_client', fullfile(native_dir, iff(ispc(), 'traxclient.exe', 'traxclient')));
else
    return;
end

if exist(fullfile(native_dir, 'mex', ['traxserver.', mexext]), 'file') == 2 || ...
    exist(fullfile(native_dir, 'mex', ['traxserver.', mexext]), 'file') == 3
    set_global_variable('trax_mex', fullfile(native_dir, 'mex'));
else
    return;
end

if exist(fullfile(native_dir, 'python'), 'dir') == 7 
    set_global_variable('trax_python', fullfile(native_dir, 'python'));
else
    return;
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

trax_url = get_global_variable('trax_url','https://github.com/votchallenge/trax/archive/master.zip');

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
    delpath(working_directory);
else
    print_debug('TraX source code already present.');
    success = true;
end;

if success
    if exist(fullfile(trax_dir, 'python'), 'dir') == 7 
        set_global_variable('trax_python', fullfile(trax_dir, 'python'));
    end 
end

end
