function container = properties_create(sequence)
% properties_create Create tracker runtime properties structure
%

container = struct();
container.names = {};
container.data = cell(sequence.length, 0);
