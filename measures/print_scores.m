function print_scores(sequences, scores)

print_text('Outputting scores:');

print_indent(1);

for i = 1:length(sequences)
    print_text('Sequence "%s" - Accuracy: %.3f, Failures: %.3f, Speed: %.3f', sequences{i}.name, scores(i, 1), scores(i, 2), scores(i, 3));
end;

print_text('Average - Accuracy: %.3f, Failures: %.3f, Speed: %.3f', mean(scores(:, 1)), mean(scores(:, 2)), mean(scores(:, 3)));

print_indent(-1);
