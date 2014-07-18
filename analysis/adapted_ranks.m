function a_ranks = adapted_ranks(ranks, different)

a_ranks = zeros(1, length(ranks)) ;

for tracker = 1:length(ranks)
    a_ranks(tracker) = mean(ranks(find(different(tracker,:) == 0))) ; %#ok<FNDSB>
end 