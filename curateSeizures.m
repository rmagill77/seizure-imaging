function szs = curateSeizures(szs)
%% curateSeizures Allows user to manually identify seizure troughs and classify seizure types
%
% INPUTS:
%   sz - structure containing information about detected seizures
%   arg2 - description of arg2
% OUTPUTS:
%   out1 - description of out1
%
% Written by Scott Kilianski
% 10/25/2022

%% Body of function here
% Plotting code below
szFig = figure; ax = axes;
yl = [-15 15]; % NEED BETTER YLIMIT STRATEGY
set(ax,'YLim',yl);
p = plot(0,0,'k','LineWidth',1.5); % initialize line plot for EEG
hold on
sc = scatter([],[],108,'ob','lineWidth',2.5); % initialize scatter for troughs
ki = 1; %intialize looping index for use below
key = 1; %initialize key (used to end while loop below)
while ~isequal(key,'return')
    set(p,'XData',szs(ki).time,...
        'YData',szs(ki).EEG)
    set(ax,'XLim',[szs(ki).time(1),szs(ki).time(end)]);
    set(ax.Title,'String',sprintf(['''a'' for previous. '...
        '''d'' for next. '...
        'Enter to add/remove peaks. '...
        'Spacebar to end curation.\n'...
        'Seizure %d - ''Type %s'''],ki,szs(ki).type));
    set(sc,'XData',szs(ki).time(szs(ki).trTimeInds),...
        'YData',szs(ki).trVals);
    [szs(ki), loopdir, key] = getuInput(szs(ki),ki,ax,sc);
    if (loopdir==1 && ki<length(szs)) || (loopdir==-1 && ki>1) % check to ensure ki doesn't go beyond szs limits
        ki = ki + loopdir;
    end
end
close(szFig);
szs(strcmp({szs.type},'remove')) = []; % removes seizures tagged for removal
% save([szs(1).filename '_curated'],'szs'); % update the saved file

end %function end

%%
function [csz, loopdir, key] = getuInput(csz,ki,ax,sc)
csz.type = csz.type;
loopdir = 0;
while ~loopdir % do I need abs()???
    bb = waitforbuttonpress; % wait for click or keyboard button
    if bb % if a keyboard button is pressed
        key= get(gcf,'CurrentKey');
        switch key
            case '1'
                csz.type = '1';
            case 'numpad1'
                csz.type = '1';
            case '2'
                csz.type = '2';
            case 'numpad2'
                csz.type = '2';
            case '3'
                csz.type = '3';
            case 'numpad3'
                csz.type = '3';
            case 'delete'
                csz.type = 'to-be-removed';
            case 'a'
                loopdir = -1;
            case 'd'
                loopdir = 1;
            case 'downarrow' % change mouse to/from zoom tool
                zoom toggle
            case 'uparrow' % rescale axes
                set(ax,'XLim',[csz.time(1),csz.time(end)]);
                set(ax,'YLim',[min(csz.EEG), max(csz.EEG)]*1.1);
            case 'numpad0'
                pan toggle
            case 'space'
                set(ax.Title,'String',...
                    ['Left-click to add peak. '...
                    'Right-click to remove peak. '...
                    'Middle click or ''Esc'' to exit peak-selection mode']);
                csz = clickPeaks(csz,sc); % go to clickPeaks function to select/remove peaks in each seizure
            case 'return'
                break % end
            otherwise
                loopdir = 0;
        end
        set(ax.Title,'String',sprintf(['''a'' for previous. '...
            '''d'' for next. '...
            'Enter to add/remove peaks. '...
            'Spacebar to end curation.\n'...
            'Seizure %d - ''Type %s'''],ki,csz.type)); % update plot title
    end
end
end % getuInput end

%%
function csz = clickPeaks(csz,sc)

[mx,my,mbutton] = ginput(1);
% FOR NOW, I AM USING THE X COORDINATE ONLY
% xSize = diff(get(gca,'XLim'));
% ySize = diff(get(gca,'YLim'));
yF = diff(get(gca,'XLim'))/diff(get(gca,'YLim')); % factor to make Y coordinate proportional to X
if mbutton == 1 % left click
    [~, minInd] = min(abs(csz.time-mx) + abs(csz.EEG-my)*yF); %find closest point in the EEG data
    [csz.trTimeInds, sidx] = sort([csz.trTimeInds; minInd]); %append new peak time index and find the new sorting order
    tmpVals = [csz.trVals; csz.EEG(minInd)]; % append new peak value
    csz.trVals = tmpVals(sidx); %resort the peak values accordingly to time order computed above
    % update scatter
    set(sc,'XData',csz.time(csz.trTimeInds),...
        'YData',csz.trVals);
elseif mbutton == 3 % right lick
    [~, minInd] = min(abs(csz.time(csz.trTimeInds)-mx) + abs(csz.trVals-my)*yF); %find closest point among the already-identified troughs/peaks
    csz.trTimeInds(minInd) = [];  % remove the timeIndex value
    csz.trVals(minInd) = []; % remove the corresponding actual value
    set(sc,'XData',csz.time(csz.trTimeInds),...
        'YData',csz.trVals);
end
end % clickPeaks end