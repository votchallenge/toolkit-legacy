function [success] = compile_mex(name, files)

if exist(name, 'file') == 3
     success = true;
     return;
end

if is_octave() 
    
    mkoctfile('-mex', '-o', name, files{:});
    
else
   
    mex('-output', name, files{:});
    
end

success = true;