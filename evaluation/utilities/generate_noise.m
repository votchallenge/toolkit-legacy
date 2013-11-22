function offsets = generate_noise(N)

maximum = 0.1;

offsets = rand(N, 4);

offsets(:, 1:2) =  (2 * maximum) * offsets(:, 1:2) - maximum;
offsets(:, 3:4) =  (2 * maximum) * offsets(:, 3:4) + (1 - maximum);




