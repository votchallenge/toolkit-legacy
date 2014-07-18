function [ha, hr] = compare_trackers(A1, R1, A2, R2, alpha, practical)
 
    % Testing accuracy significance
    
    % Statistical test
    dif = A1 - A2;
    dif = dif(~isnan(dif)) ;
    if (length(dif) < 5)
        print_text('Warning: less than 5 samples when comparing tracker %s and %s', tracker1.identifier, tracker2.identifier);
        ha = 0;
    else
        if (is_octave)
            pa = wilcoxon_test(A1, A2);
            ha = (pa <= alpha);
        else
            [~, ha, ~] = signrank(dif, [], 'alpha', alpha ) ;
        end;
        e = sum(abs(dif) <= minimal_difference) / length(dif);
        if (e > 0.95)
            ha = 0;
        end;  
    end;               
    
    % Practical difference of accuracy
    if ~isempty(practical)

        if mean(dif ./ practical) < 1
            ha = 0;
        end;
        
    end;
    
    % Testing robustness significance
    if (is_octave)
        pr = u_test(R1, R2);
        hr = (pr <= alpha);
    else
        [~, hr] = ranksum(R1, R2, 'alpha', alpha) ;
    end;            

