function [directory] = generate_crash_report(tracker, context)

runtime_log = fullfile(context.directory, 'runtime.log'); % Log produced by tracker directly
trax_log = fullfile(context.directory, 'trax.log'); % Log produced by TraX client

directory = fullfile(get_global_variable('directory'), 'logs', tracker.identifier, datestr(now, 30));

mkpath(directory);

if exist(runtime_log, 'file') == 2
   copyfile(runtime_log, directory);
end

if exist(trax_log, 'file') == 2
   copyfile(trax_log, directory);
end

write_manifest(tracker, directory);