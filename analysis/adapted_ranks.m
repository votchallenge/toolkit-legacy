function adapted = adapted_ranks(ranks, different, mode)
% adapted_ranks Performs rank adaptation on a set of ranks
%
% Input:
% - ranks (integer): A
% - different (boolean matrix): A index of a frame or a vector of indices of frames.
% - 
%
% Output
% - region: A region description matrix or a cell array of region description matrices if more than one frame was requested.

adapted = zeros(1, length(ranks)) ;

switch mode

	case 'mean'

		for tracker = 1:length(ranks)
			adapted(tracker) = mean(ranks(find(~different(tracker,:)))) ; %#ok<FNDSB>
		end 

	case 'median'

		for tracker = 1:length(ranks)
			adapted(tracker) = median(ranks(find(~different(tracker,:)))) ; %#ok<FNDSB>
		end 

	case 'best'

		for tracker = 1:length(ranks)
			adapted(tracker) = min(ranks(find(~different(tracker,:)))) ; %#ok<FNDSB>
		end 

	case 'reranked'

		for tracker = 1:length(ranks)
            adapted(tracker) = min(ranks(find(different(tracker,:) == 0)));  %#ok<FNDSB>
        end 

        [~, ~, reranked] = unique(adapted);
        adapted = reranked; 

end;
