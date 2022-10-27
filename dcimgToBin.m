function dcimgToBin(filename)
%%
% dcimgToBin converts image data in .dcimg files to .imgbin files, which are binary files that Matlab can read easily
% INPUTS:
%   filename - full path to the directory containing RHD files
% OUTPUTS:
%   NONE - the .imgbin file is saved to the same directory with the same name as the .dcimg file; only the extension changes (to .imgbin)
%
% Written by Scott Kilianski
% 10/11/2022

%%
filename = 'Z:\SI_Project\SI_005\20220930\00001.dcimg';
[pth,nm,ext] = fileparts(filename);
foutN = fullfile(pth,strcat(nm,'.imgbin'));                   % filename of the output file (.imgbin)
foutID = fopen(foutN,'w');                                 % fopen the fout file
hdcimg = dcimgmex('open',filename);                     % open the original .dcimg file
imgWidth = dcimgmex('getparam',hdcimg,'IMAGE_WIDTH');   % retrieve the width of the image (in pixels)
imgHeight = dcimgmex('getparam',hdcimg,'IMAGE_HEIGHT'); % retrieve the height of the image (in pixels)
nof = dcimgmex('getparam',hdcimg,'NUMBEROF_FRAME');     % retrieve the total number of frames in the session
rwbar = waitbar(0/nof,...
    'Reading images from .dcimg and writing to .imgbin');  % start a waitbar to track progress read/write stage below
fwrite(foutID,nof,'int32','l');                           % write total number of frames as int32
fwrite(foutID,imgWidth,'int32','l');                      % write Width as int32
fwrite(foutID,imgHeight,'int32','l');                     % write Height as int32

%% Read in one image and at time and write to the .imgbin file
% CAN I USE PARALLEL LOOPING HERE? Maybe not if I do this serially, but I
% can use 'readframe' method rather than 'readnext' and maybe make it work
% If I do that, do I have to initialize the structure and then assign values to certain indices???
rwClock = tic;
while ~dcimgmex('iseof', hdcimg) % check if end of file
    loopClock = tic;
    imgData = dcimgmex('readnext', hdcimg)';% read in next frame
    fwrite(foutID,imgData,'uint16','l');% write imgData as int16
    cf = dcimgmex('getparam',hdcimg,...
        'CURRENT_FRAMEINDEX');              % read the number of the current frame
    waitbar(double(cf)/double(nof),rwbar);  % update waitbar status
    fprintf('Loop cf: %.2f seconds\n',toc(loopClock));
end
fprintf('Read-write process took %.2f minutes\n',toc(rwClock)/60);
dcimgmex('close',hdcimg);
fclose(foutID);
close(rwbar);
% figure; imagesc(imgData); title('Image from dcimgmex');
end % function end