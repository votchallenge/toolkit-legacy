function adapted = adapted_ranks(ranks, different, mode)
% adapted_ranks Performs rank adaptation on a set of ranks
%
% Performs different types of rank adaptation on a set of ranks and a matrix of determined actual differences of ranked entities. 
%
% The function looks for sets of entities that are considered equal according to the `different` matrix and adapts their ranks
% in one of the following ways:
% - none: no adaptation, keep the original ranks.
% - mean: a mean rank of a set is assigned to all trackers in the set.
% - median: a median rank of a set is assigned to all trackers in the set.
% - best: a minimum rank in a set is assigned to all trackers in the set.
%
% Input:
% - ranks (double vector): A vector of `N` ranks.
% - different (boolean matrix): A `N x N` matrix that denotes which entities should actually be equal and which not. 
% - mode (string): Type of rank adaptation.
%
% Output
% - adapted (double vector): Adapted ranks 

adapted = zeros(1, length(ranks)) ;

switch mode
	case 'none'
        adapted = ranks;
    
	case 'mean'

		for tracker = 1:length(ranks)
			adapted(tracker) = mean(ranks(find(~different(tracker,:)))) ; %#ok<FNDSB>
		end 

	case 'median'

		for tracker = 1:length(ranks)
			adapted(tracker) = median(ranks(find(~different(tracker,:)))) ; %#ok<FNDSB>
		end 

	case 'best'

        [sorted_ranks, idx] = sort(ranks);
        [~, unsort_idx] = sort(idx);

        sorted_matrix = different(idx,idx);

        for tracker = 2:length(ranks)
            if sorted_matrix(tracker,tracker-1)
                sorted_ranks(tracker) = sorted_ranks(tracker-1);
            end;
        end;
        adapted = sorted_ranks(unsort_idx);

	%	for tracker = 1:length(ranks)
	%		adapted(tracker) = min(ranks(find(~different(tracker,:)))) ; %#ok<FNDSB>
	%	end 

end;
