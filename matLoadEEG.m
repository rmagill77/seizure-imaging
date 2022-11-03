function EEG = matLoadEEG(filename,eegChannel,targetFS)
%%
% matLoadEEG loads and downsamples the EEG data from a MATLAB data file
% (.mat) created by exporting from LabChart
% INPUTS:
%   filename - full file name to the .adicht file (including path)
%   eegChannel - channel number of the EEG, typically 1
%   targetFS - desired sampling frequency. This is useful for downsampling EEG data and making it easier to work with
% OUTPUTS:
%   EEG - a structure with following fields related to EEG signal:
%       data - actual values of EEG (in volts)
%       time - times corresponding to values in data field (in seconds)
%       tartgetFS - target sampling frequency specified by user (in samples/second)
%       finalFS - the sampling frequency ultimately used (in
%       samples/second)
%
% Written by Scott Kilianski 
% 11/3/2022

%% Set defaults as needed if not user-specific by inputs
if ~exist('eegChannel','var')
    eegChannel = 1; %default
end
if ~exist('targetFS','var') 
   targetFS = 200; %default
end

%% Load raw data from .mat and downsample
funClock = tic;     % function clock
fprintf('Loading data in\n%s...\n',filename);
load(filename,'data',...
    'datastart','dataend','samplerate');
dt = 1/samplerate(eegChannel); % time step
dsFactor = floor(samplerate(eegChannel) / targetFS);% downsampling factor to achieve targetFS
finalFS = samplerate(eegChannel) / dsFactor;   % calculate ultimate sampling frequency to be used 
EEGdata = data(datastart(eegChannel):dsFactor:dataend(eegChannel))'; % extract and downsample raw data
EEGtime = ((datastart(eegChannel)-1):dsFactor:(dataend(eegChannel)-1))'.*dt; % create corresponding time vector

%% Create output structure and assign values to fields
EEG = struct('data',EEGdata,...
    'time',EEGtime,...
    'finalFS',finalFS);
fprintf('Loading data took %.2f seconds\n',toc(funClock));

end % function end