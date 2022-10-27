function img = imgbinRead(filename)
%% imgbinRead Maps data in .imgbin file using memmapfile
% 
% INPUTS:
%   filename - full path to .imgbin file
% OUTPUTS:
%   img - memmapfile object. img.Data.frames contains height X width X # of frames-sized matrix
%
% Written by Scott Kilianski
% 10/18/2022

%% Read in "header" (# of frames, height, width). Then memmap image data
finID = fopen(filename,'r');    % open .imgbin file for reading
imgDims = fread(finID,3,'int32','l'); % imgDims(1) is number of frames. (2) is height. (3) is width
fclose(finID);              % close .imgbin file
img = memmapfile(filename,'Offset',12,...
'Format',{'uint16',[imgDims(2),imgDims(3),imgDims(1)],'frames'}); % read in data by memory map method

end %function end
