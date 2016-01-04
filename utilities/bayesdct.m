function measure = bayesdct( X, W, lo, hi ) 
% Evaluates Bayes-Entropy measure of focus of an image X
% Input:
%  X  ... grayscale image
%  W  ... subwindow size, e.g. [8,8] means eight by eight pixels subwindow
%  lo ... the lowest order coefficient used by measure
%  hi ... the highest order coefficient used by measure
% Output:
%  measure ... the Bayes-Entropy focus measure
% Default values (from the paper cited below) :
%  W = [8,8] ,  lo = 0 , hi = 6
% Reference paper:
%   M. Kristan, J. Per�, M. Per�e, S. Kova�i�. 
%   "A Bayes-Spectral-Entropy-Based Measure of Camera Focus Using 
%   a Discrete Cosine Transform". Pattern Recognition Letters, 
%   27(13): 1419-1580, October 2006.
%
% Matej Kristan, 2007

m = W(1) ;
n = W(2) ; 
[r,s] = size(X) ;
overlap = 1 ;

C1 = dct(eye(m));
C2 = dct(eye(n))';
M = [] ;
measure = 0 ;
pp = 0 ;
pT = 3 ;

I = zeros( W ) ;
for y = 1 : W(1)
        x0 = lo - y + 2 ; 
        if ( x0 < 1 ) x0 = 1 ; end
        x1 = hi - y +2 ;
        if ( x1 > W(2) ) x1 = W(2) ; end 
        I(y,x0:x1) = 1 ;
end

for i = 1 : floor( ( r/m ) / overlap )
    e = (i-1)*m*overlap + 1 ;
    e = floor(e) ;
    if ( e + m > r+1 ) break; end
    for j = 1 : floor( (s/n) / overlap )  
        f = (j-1)*n*overlap + 1 ;     
        f = floor(f) ;
        if ( f + n > s+1 ) break; end  
        
        Z = X(e:(e+m-1),(f:f+n-1));
        G = C1*Z*C2 ;  
        G = abs(G.*I) ;
        
        SS  = sum(sum( G )).^2  ;
        if ( SS == 0 ) 
            E = -1 ; 
        else
            E = sum( sum( G.^2 )) / SS ;
        end

        M = [ M, E] ;
    end;    
end;

measure = mean(M);
measure = (1 - measure) ;
