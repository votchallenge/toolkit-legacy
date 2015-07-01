function filename = benchmark_hardware(varargin)
% benchmark_hardware Perform a simple hardware benchmark
%
% Performs a simple benchmark of the computer that can be later used to normalize
% the speed estimate between results obtained on different hardware.
%
% Output:
% - filename: Path to the local performance profile.
%
filename = fullfile(get_global_variable('directory'), 'results', 'performance.txt');

if exist(filename, 'file')
    print_debug('Skipping hardware performance benchmark');
    return;
end;

print_text('Performing hardware performance benchmark');

print_indent(1);

performance = struct('reading', NaN, ...
    'convolution_native', NaN, 'convolution_matlab', NaN, ...
    'nonlinear_native', NaN);

repetitions = 20;

temporary_dir = tempdir;

image_file = fullfile(temporary_dir, 'image.jpg');

print_debug('Performing IO image reading benchmark');

I = rand(600, 600);
imwrite(I, image_file);

tic;

for i = 1:repetitions
    imread(image_file);
end;

performance.reading = toc / repetitions;

delete(image_file);

print_debug('Performing native convolution filter benchmark');

I = rand(600, 600);
K = rand(30, 30);

tic;

for i = 1:repetitions
    benchmark_native('convolution', I, K);
end;

performance.convolution_native = toc / repetitions;

print_debug('Performing Matlab convolution filter benchmark');

I = rand(600, 600);
K = rand(30, 30);

tic;

for i = 1:repetitions
    conv2(I, K);
end;

performance.convolution_matlab = toc / repetitions;

print_debug('Performing native nonlinear max filter benchmark');

I = rand(600, 600);

tic;

for i = 1:repetitions
    benchmark_native('maxfilter', I, 20, 20);
end;

performance.nonlinear_native = toc / repetitions;

if ~is_octave()
	print_debug('Performing Matlab startup time benchmark');

	time_file = fullfile(pwd, 'time.txt');

	if isunix
		matlab_executable = [fullfile(strrep(matlabroot, ' ', '\ '), 'bin', 'matlab'), ' -nodesktop -nosplash -r "dlmwrite(''', time_file, ''', now, ''precision'', 30); quit;"'];
	else
		matlab_executable = ['"', fullfile(matlabroot, 'bin', 'matlab.exe'), '" -nodesktop -nosplash -wait -minimize -r "dlmwrite(''', time_file, ''', now, ''precision'', 30); quit;"'];
	end

	try

		repetitions = 3;

		totaltime = 0;
        
		for i = 1:repetitions

            if exist(time_file, 'file')
                delete(time_file);
            end;

            startime = now;

			if verLessThan('matlab', '7.14.0')
				[result, output] = system(matlab_executable);
			else
				[result, output] = system(matlab_executable, '');
			end;

            endtime = NaN;
            
            for w = 1:500
      
                if exist(time_file, 'file')
                    endtime = csvread(time_file);
                    delete(time_file);
					break;
                end;
                pause(0.1);
            end;
            
            if isnan(endtime)
                print_debug('ERROR: Unable to time Matlab: timeout.');
            end;

            totaltime = totaltime + (endtime - startime) * 86400;
            
		end;

		performance.matlab_startup = totaltime / repetitions;

	catch e

		print_debug('ERROR: Exception thrown "%s".', e.message);
	end;
end

[platform_str,platform_maxsize,platform_endian] = computer();

performance.platform = platform_str;
performance.platform_maxsize = platform_maxsize;
performance.platform_endian = platform_endian;

writestruct(filename, performance);

print_indent(-1);
