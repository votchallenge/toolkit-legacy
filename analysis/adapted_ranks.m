function a_ranks = adapted_ranks(ranks, different, mode)

a_ranks = zeros(1, length(ranks)) ;

switch mode

	case 'mean'

		for tracker = 1:length(ranks)
			a_ranks(tracker) = mean(ranks(find(~different(tracker,:)))) ; %#ok<FNDSB>
		end 

	case 'median'

		for tracker = 1:length(ranks)
			a_ranks(tracker) = median(ranks(find(~different(tracker,:)))) ; %#ok<FNDSB>
		end 

	case 'best'

		for tracker = 1:length(ranks)
			a_ranks(tracker) = min(ranks(find(~different(tracker,:)))) ; %#ok<FNDSB>
		end 

	case 'reranked'

		for tracker = 1:length(ranks)
            a_ranks(tracker) = min(ranks(find(different(tracker,:) == 0)));  %#ok<FNDSB>
        end 

        [~, ~, reranked] = unique(a_ranks);
        a_ranks = reranked; 

end;
