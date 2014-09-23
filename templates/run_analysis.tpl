% This script can be used to perform a comparative analyis of the experiments
% in the same manner as for the VOT challenge
% You can copy and modify it to create a different analyis

[sequences, experiments] = vot_environment();

error('Analysis not configured!'); % Remove this line after proper configuration

trackers = create_trackers('{{tracker}}', 'TODO'); % TODO: add more trackers here

context = create_report_context('report_{{stack}}_{{tracker}}');

report_challenge(context, experiments, trackers, sequences);

