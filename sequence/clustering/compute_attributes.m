function [] = compute_attributes(config, sequences)
% compute_attributes Calculates automatic sequence attributes for given
% sequences
%
% The function calculates all attributes set in config strut for all sequences 
% if there are not already computed (and flag config.loadPrevious is set to 1)
%
% Input:
% - config (structure): config structure
% - sequence (structure): A valid sequence structure.
%
% Output: (computed attributes are store in local file system)
% - none

    disp('Computing attributes, Processing sequences ...');
    numAttr = length(config.attributes);
    allTime = tic ;
    for i = 1:length(sequences)
      disp([num2str(i) '/' num2str(length(sequences)) ' - ' sequences{i}.name]);

      mean_file = fullfile(config.result_directory, sprintf('%s.mean', sequences{i}.name));
      var_file = fullfile(config.result_directory, sprintf('%s.var', sequences{i}.name));
      frames_file = fullfile(config.result_directory, sprintf('%s.frames', sequences{i}.name));

      start_attr_index = 1;
      if config.loadPrevious == 1 && exist(mean_file, 'file') 
          data = csvread(mean_file);
          if length(data) == numAttr
              continue;
          elseif length(data) < numAttr
              means = zeros(numAttr, 1);
              means(1:length(data)) = csvread(mean_file);

              vars = zeros(numAttr, 1);
              vars(1:length(data)) = csvread(var_file);

              frames = zeros(numAttr, sequences{i}.length);
              frames(1:length(data), :) = csvread(frames_file);
              start_attr_index = length(data) + 1;
          else
              means = zeros(numAttr, 1);
              vars = zeros(numAttr, 1);
              frames = zeros(numAttr, sequences{i}.length);
          end
      else    
          means = zeros(numAttr, 1);
          vars = zeros(numAttr, 1);
          frames = zeros(numAttr, sequences{i}.length);
      end


      tic
      for j = start_attr_index:numAttr
        disp(['        ' num2str(j) '/' num2str(numAttr) ' - ' config.attributes{j}]);
        attrfnc = str2func(config.attributes{j});
        [means(j) vars(j) frames(j, :)] = attrfnc(sequences{i});
      end
      toc

      csvwrite(mean_file, means);
      csvwrite(var_file, vars);
      csvwrite(frames_file, frames);
    end;
    t = toc(allTime);
    disp(['Attributes computation finnished in ' num2str(t) 's']);
end
