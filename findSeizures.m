function seizures = findSeizures(varargin)%pband, ptCut, ttv, eegChannel, targetFS)
%% findSeizures Finds seizures in an EEG/LFP traces based on power thresholding in
%
% INPUTS:
%   filename - full file path to file with EEG data
%   pband - passband filter limits for seizure detection (default = [4 8])
%   ttv - trough threshold value. This value is multipled by the standard
%         deviation of the EEG to set a threshold that seizure troughs must
%         pass (default = 3)
%   ptCut - percentile cuttoff threshold. This value determines the
%           threshold for detecting potential seizures by bandpower thresholding (default = 99)
%   eegChannel - channel number of the EEG (usually 1 or 2) (default = 1)
%   targetFS - target sampling frequency. Used to downsample data to
%              reduce computational load (default = 200)
% OUTPUTS:
%   sz - structure containing information about seizures
%
% Written by Scott Kilianski
% Updated 11/1/2022

%% Parse inputs
validScalarNum = @(x) isnumeric(x) && isscalar(x);
default_filename = [];
default_pband = [4 8];
default_ptCut = 95;
default_ttv = 3;
default_eegChannel = 1;
default_targetFS = 200;
default_plotFlag = 1;
p = inputParser;
addParameter(p,'filename',default_filename,@(x) isstring(x));
addParameter(p,'pband',default_pband,@(x) numel(x)==2);
addParameter(p,'ptCut',default_ptCut,validScalarNum);
addParameter(p,'ttv',default_ttv,validScalarNum);
addParameter(p,'eegChannel',default_eegChannel,validScalarNum);
addParameter(p,'targetFS',default_targetFS);
addParameter(p,'plotFlag',default_plotFlag);
parse(p,varargin{:});
filename = p.Results.filename;
pband = p.Results.pband;
ptCut = p.Results.ptCut;
ttv = p.Results.ttv;
eegChannel = p.Results.eegChannel;
targetFS = p.Results.targetFS;
plotFlag = p.Results.plotFlag;
detectionParameters(1,:) = {'pband','ptCut','ttv','eegChannel','targetFS'};
detectionParameters(2,:) = {pband,ptCut,ttv,eegChannel,targetFS};

%% Load in data
if isempty(filename)
    [fn,fp,rv] = uigetfile({'*.mat;*.adicht;*.rhd'});
    if ~rv % if no file selected, end function early
        return
    else
        filename = fullfile(fp,fn);
    end
end
[fp, fn, fext] = fileparts(filename);   % get file name, path, and extension
if strcmp(fext,'.adicht')
    EEG = adiLoadEEG(filename,eegChannel,targetFS);     % loads .adicht files
elseif strcmp(fext,'.rhd')
    EEG = intanLoadEEG(filename,eegChannel,targetFS);   % loads .rhd files
elseif strcmp(fext,'.mat')
    EEG = matLoadEEG(filename,eegChannel,targetFS);     % loads .mat files that were exported from LabChart
else
    error('File type unrecognized. Use .rhd, .adicht, .mat file types only');
end

%% Calculate spectrogram and threshold bandpower in band specificed by pband
frange = [0 50];                                            % frequency range used for spectrogram
[spectrogram,t,f] = MTSpectrogram([EEG.time, EEG.data*100],...
    'window',1,'overlap',0.75,'range',frange);              % computes the spectrogram
bands = SpectrogramBands(spectrogram,f,'broadLow',pband);   % computes power in different bands

% Find where power crosses threhold (rising and falling edge)
tVal = prctile(bands.broadLow, ptCut);          % find the bandpower threshold value based on percentile threshold (ptCut)
riseI = find(diff(bands.broadLow>tVal)>0) + 1;  % seizure rising edge index
fallI = find(diff(bands.broadLow>tVal)<0) + 1;  % seizure falling edge index

%% Find putative seizures, merge those that happen close in time, detect troughs, and store everything in structure(sz)
pzit = 2; % gap length under which to merge (seconds)
mszt = .5; % minimum seizure time duration (seconds)
ttv = -std(EEG.data)*ttv; % calculate trough threshold value (standard deviation * user-defined multiplier)
tb = 2; % time buffer (in seconds) - time to grab before and after each detected seizure
startEnd = [t(riseI)-tb,t(fallI)+tb]; %seizure start and end times
startEnd_interp = interp1(EEG.time,EEG.time,...
    startEnd,'nearest'); % interpolate from spectrogram time to nearest EEG timestamps
startEnd_interp = szmerge(startEnd_interp, pzit); % merge seizure if/when appropriate
tooShortLog = diff(startEnd_interp,1,2)<mszt; % find too-short seizures
startEnd_interp(tooShortLog,:) = []; % remove seizures that are too short
ts = cell2mat(arrayfun(@(x) find(x==EEG.time), ...
    startEnd_interp,...
    'UniformOutput',0)); % getting start and end indices
outfn = sprintf('%s%sseizures.mat',fp,'\'); % name of the output file
for ii = 1:size(ts,1)
    eegInd = ts(ii,1):ts(ii,2);
    seizures(ii).time = EEG.time(eegInd); % find EEG.time-referenced.
    seizures(ii).EEG = EEG.data(eegInd);
    seizures(ii).type = 'Unclassified';
    [trgh, locs] = findpeaks(-seizures(ii).EEG); % find troughs (negative peaks)
    locs(-trgh>ttv) = []; % remove those troughs that don't cross the threshold (ttv)
    trgh(-trgh>ttv) = []; % remove those troughs that don't cross the threshold (ttv)
    seizures(ii).trTimeInds = locs; seizures(ii).trVals = -trgh; % store trough time (indices) and values in sz structure
    seizures(ii).filename = outfn;
    seizures(ii).parameters = detectionParameters;
end

%% Plotting trace, thresholds, and identified putative seizures
if plotFlag % plotting option
figure; ax(1) = subplot(311);
plot(EEG.time, EEG.data,'k','LineWidth',2); title('EEG');
hold on
plot(get(gca,'xlim'),[ttv,ttv],'b','linewidth',1.5); hold off;
ax(2) = subplot(312);
plot(t,bands.broadLow,'k','linewidth',2); 
title(sprintf('Power in %d-%dHz Range',pband(1),pband(2)));
hold on
plot(get(gca,'xlim'),[tVal,tVal],'r','linewidth',1.5); hold off;
ax(3) = subplot(313);
cutoffs = [3 8];
PlotColorMap(log(spectrogram),1,'x',t,'y',f,'cutoffs',cutoffs);
title('Spectrogram'); xlabel('Time (sec)'); ylabel('Frequency (Hz)');
linkaxes(ax,'x');
axes(ax(1)); hold on;
yl = get(gca,'YLim');
for ii = 1:size(startEnd_interp,1)
    patch([startEnd_interp(ii,:),fliplr(startEnd_interp(ii,:))],...
        [yl(1),yl(1),yl(2),yl(2)],'g',...
        'EdgeColor','none','FaceAlpha',0.25);
end
end % plotting option end


try % try statement here because sometimes saving fails due to insufficient permissions
    save(outfn,'seizures'); % save output into same folder as filename
    fprintf('seizures.mat saved in %s\n',fileparts(outfn))
catch
    fprintf('seizures.mat could not be saved in %s, likely because of insufficient permissions\n',fileparts(outfn))
end

end %main function end

function startEnd_interp = szmerge(startEnd_interp, pzit)
%szmerge Merges overlapping or close-in-time seizures
pzInts = startEnd_interp(2:end,1)-startEnd_interp(1:end-1,2); % intervals between putative seizures
fprintf('Merging putative seizures if/when appropriate...\n')
tmInd = find(pzInts<pzit,1,'first'); % index of 1st putative seizure pair to merge
while tmInd % if putative seizures to merge, do it, then check for more
    startEnd_interp(tmInd,2) = startEnd_interp(tmInd+1,2); % replace the end time
    startEnd_interp(tmInd+1,:) = []; % remove 2nd putative seizure in the pair
    pzInts = startEnd_interp(2:end,1)-startEnd_interp(1:end-1,2); % intervals between putative seizures
    tmInd = find(pzInts<pzit,1,'first'); % check for more pairs to merge
end

end % szmerge function end
