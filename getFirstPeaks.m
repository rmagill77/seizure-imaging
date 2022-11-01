function firstPeakTimes = getFirstPeaks(seizures)
%% firstPeaksTimes Gets time of the first peaks for each seizures
%
% INPUTS:
%   seizures - structure containing information about detected seizures (output of findSeizures)
%
% OUTPUTS:
%   firstPeakTimes - vector containing the time (in seconds) of the first peak in each detected seizure 
%
% Written by Scott Kilianski
% Updated 11/1/2022

for ii = 1:length(seizures)
    try
        firstPeakTimes(ii) = seizures(ii).time(seizures(ii).trTimeInds(1)); % retrieve time of 1st peak 
    catch 
        firstPeakTimes(ii) = nan;
    end
end

end % function end