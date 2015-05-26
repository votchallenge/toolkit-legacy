function [estimate] = estimate_completion_time(sequences, varargin)
% estimate_completion_time Estimates completion time for a tracker
%
% Estimates time for a pass over a given set of sequences given some basic performance characteristics.
%
% Input:
% - sequences: Cell array of sequence structures.
% - varargin[FPS]: Average speed of a tracker (frames per second).
% - varargin[Failures]: Average number of failures per sequence.
% - varargin[Repeats]: Required number of repetitions for each sequence.
%
% Output:
% - estimate: Completion time estimate given in number of seconds

failures = 8;
fps = 0.5;
repeats = 1;

args = varargin;
for j=1:2:length(args)
    switch varargin{j}
        case 'fps', fps = max(0, args{j+1});
        case 'failures', failures = max(0, args{j+1});
        case 'repeats', repeats = max(1, args{j+1});
        otherwise, error(['unrecognized argument ' args{j}]);
    end
end

total_frames = 0;

for i = 1:length(sequences)
    total_frames = total_frames + sequences{i}.length;
end;

average_frames = total_frames / length(sequences);

lens = linspace(0, 1, failures + 1);
reruns = sum(lens);

estimate = (average_frames * reruns * repeats) * length(sequences) / fps;

