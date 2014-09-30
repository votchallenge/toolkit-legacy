% This script can be used to pack the results and submit them to a challenge.

[sequences, experiments] = vot_environment();

tracker = create_tracker('{{tracker}}');

vot_pack(tracker, sequences, experiments);

