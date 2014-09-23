% This script can be used to perform a comparative analyis of the experiments
% in the same manner as for the VOT challenge
% You can copy and modify it to create a different analyis

[sequences, experiments] = vot_environment();

trackers = create_trackers('{{tracker}}'); % TODO: add more trackers here

context = create_report_context('report_{{tracker}}'); % TODO: name of the report

report_challenge(context, experiments, trackers, sequences);

