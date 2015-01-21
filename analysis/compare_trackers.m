function [ha, hr] = compare_trackers(A1, R1, A2, R2, alpha, practical)
 
    % Testing accuracy significance
    
    % Statistical test
    dif = A1 - A2;
	valid = ~isnan(dif);
    dif = dif(valid) ;
    if (length(dif) < 5)
        print_text('Warning: less than 5 samples when comparing trackers.');
        ha = 0;
    else
		%dif(abs(dif)' < practical(valid)) = 0;
        if (is_octave)
            pa = wilcoxon_test(A1, A2);
            ha = (pa <= alpha);
        else
            [~, ha, ~] = signrank(dif, [], 'alpha', alpha ) ;
        end;
    end;               
  
    % Practical difference of accuracy
    if ~isempty(practical)
        if abs(mean(dif' ./ practical(valid))) < 1
            ha = 0;
        end;
        
    end;
    
    % Testing robustness significance
   R1 = R1(:);
   R2 = R2(:);
   if (is_octave)
       pr = u_test(R1, R2);
       hr = (pr <= alpha);
   else
       [~, hr] = ranksum(R1, R2, 'alpha', alpha) ;
   end;

