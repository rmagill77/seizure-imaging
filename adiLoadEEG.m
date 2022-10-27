function EEG = adiLoadEEG(filename,eegChannel,targetFS)
%%
% adiLoadEEG loads and downsamples the EEG data from a LabChart data file (.adicht)
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
% 10/10/2022

%% Set defaults as needed if not user-specific by inputs
if ~exist('eegChannel','var')
    eegChannel = 1; %default
end
if ~exist('targetFS','var') 
   targetFS = 200; %default
end

%% Load raw data from .adicht and downsample
funClock = tic;     % function clock
fprintf('Loading data in\n%s...\n',filename);
ad = adi.readFile(filename);        % loading function from LabChart's Matlab SDK (https://www.mathworks.com/matlabcentral/fileexchange/50520-adinstruments-labchart-sdk)
dsFactor = floor(ad.channel_specs(eegChannel).fs / targetFS);% downsampling factor to achieve targetFS
finalFS = ad.channel_specs(eegChannel).fs / dsFactor;   % calculate ultimate sampling frequency to be used 
EEGdata = ad.getChannelData(eegChannel,1); % extract raw data
EEGdata = EEGdata(1:dsFactor:end); % downsample raw data
EEGtime = (0:dsFactor:ad.channel_specs(eegChannel).n_samples-1)'...
    *ad.channel_specs(eegChannel).dt; % create corresponding time vector

%% Create output structure and assign values to fields
EEG = struct('data',EEGdata,...
    'time',EEGtime,...
    'finalFS',finalFS);
fprintf('Loading data took %.2f seconds\n',toc(funClock));

end % function end