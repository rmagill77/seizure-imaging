%% Dropped frame check
[fn, fp] = uigetfile('*.adicht');
filename = [fp,fn];
EEG = adiLoadEEG(filename,2,20000);
x = EEG.data>3; % generating TTL trace
rte = diff(x)>0; %rising TTL edges
z = diff(x)<0; %falling TTL edges
yi = find(rte); % indices of rising edges
zi = find(z); % indices of falling edges
figure;
histogram(zi-yi); % histogram of difference between rising and falling (estimate of exposure time)
histogram(diff(yi)); % histogram of intervals between rising edges (inter-frame interval)

%%
[fn,fp] = uigetfile('*.dcimg');
dcimg_filename = [fp,fn];
hdcimg = dcimgmex('open',dcimg_filename);                     % open the original .dcimg file
nof = dcimgmex('getparam',hdcimg,'NUMBEROF_FRAME');     % retrieve the total number of frames in the session
dcimgmex('close',hdcimg);

ndf = sum(rte) - nof; %number of dropped frames (# rising TTL edges minus number of frames)
if ndf %if number of dropped frames isn't 0, find where the frames were else
    fprintf('%d dropped frames. Identifying times of dropped frames...\n',ndf);
    %%% HERE'S WHERE I HAVE TO CHECK THE INTER-FRAME INTERVALS %%%
else
    fprintf('No dropped frames! Woohoooo!\n');
end

fprintf('Assigning times to frames...\n');
fprintf('Frames are now accurately timestamped.\n')