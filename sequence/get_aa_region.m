function [ region ] = get_aa_region( sequence, frame )

region = sequence.groundtruth{frame};

if length(region) > 4
    %convert to axis-align bbox
    center = [mean(region(1:2:end)) mean(region(2:2:end))];
    w = max(region(1:2:end)) - min(region(1:2:end));
    h = max(region(2:2:end)) - min(region(2:2:end));
    
    %get rotation angle
    vect = region(3:4) - region(1:2);
    vect_axis = [1 0];
    omega = (vect*vect_axis')/norm(vect);
    angle = (acos(omega)*180/3.14 - 90);
    
    %scale linearly the size based on angle up to 80% of the max size
    %line params m slope; b y-intercept
    C = 0.8; 
    b = 1.0;
    m = (C - b)/45.0;
    scaleFactor = m*angle + b;
    if (scaleFactor - C) < 0
        scaleFactor = C + (C-scaleFactor);
    end
    
    w = w*scaleFactor;
    h = h*scaleFactor;
    
    region = [center-[w/2 h/2] w h];
    
    %boundary checks
    region(1) = max(0, min(region(1), sequence.width));
    region(2) = max(0, min(region(2), sequence.height));
    region(3) = min([region(1)+region(3) sequence.width])-region(1);
    region(4) = min([region(2)+region(4) sequence.height])-region(2);
end


end

