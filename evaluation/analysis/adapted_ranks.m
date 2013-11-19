function Ra = adapted_ranks(R, H)

Ra = zeros(1, length(R)) ;
for i_tracker=1:length(R)
    id_equivalent = find(H(i_tracker,:)==0) ;
    Ra(i_tracker) = mean(R(id_equivalent)) ; %#ok<FNDSB>
end 