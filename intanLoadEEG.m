function EEG = intanLoadEEG(dirname,eegChannel,targetFS)
%%
% intanLoadEEG loads and downsamples EEG data from an Intan RHD file(s)
% INPUTS:
%   dirname - full path to the directory containing RHD files
%   eegChannel - channel number of the EEG, typically 1. Also allowed is a 2-element vector. If given, this will produce a 2-element structure output, one for each of the 2 analog channels in the Intan RHD file(s)
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

%% Navigate directory and properly structure filepaths
funClock = tic;     % function clock
fprintf('Loading analog data in\n%s...\n',dirname);
rhdList = dir(dirname); %get structure for directory with RHD files
rhdList = rhdList(contains({rhdList.name},'.rhd')); % keep only files with .rhd extension

%% Load and concatenate analog data from RHD files
EEGdata = []; EEGtime = []; % intialize EEGdata and EEGtime because they get concatenated in the loop below
for fi = 1:numel(rhdList)
    fprintf('Loading analog data from file %d of %d total RHD files...\n',fi,numel(rhdList));
    currRHDdata = sk_readRHD(fullfile(rhdList(fi).folder,rhdList(fi).name));
    EEGdata = [EEGdata, currRHDdata.board_adc_data];
    EEGtime = [EEGtime, currRHDdata.t_amplifier];
end

%% Downsample and format data
dsFactor = floor(currRHDdata.sample_rate / targetFS);% downsampling factor to achieve targetFS
finalFS = currRHDdata.sample_rate / dsFactor;   % calculate ultimate sampling frequency to be used
EEGdata = EEGdata(eegChannel,1:dsFactor:end); % downsample raw data 
EEGtime = double(EEGtime(1:dsFactor:end)) / currRHDdata.sample_rate; % create corresponding time vector

%% Create output structure and assign values to fields
EEG = struct('data',EEGdata',...
    'time',EEGtime',...
    'finalFS',finalFS);
fprintf('Loading data took %.2f seconds\n',toc(funClock));

end % function end