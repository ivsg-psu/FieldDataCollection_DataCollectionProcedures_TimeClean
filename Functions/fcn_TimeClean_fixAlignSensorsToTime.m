function fixedDataStructure = fcn_TimeClean_fixAlignSensorsToTime(dataStructure,varargin)
% fcn_TimeClean_fixAlignSensorsToTime Aligns sensor readings to the
% Trigger_Time field for all sensors. This is done by using the
% GPSfromROS_Time to identify which indices should be saved in each sensor.
%
% FORMAT:
%
%      fixedDataStructure = fcn_TimeClean_fixAlignSensorsToTime(dataStructure, (sensorType), (fid))
%
% INPUTS:
%
%      dataStructure: a data structure to be analyzed that has sensors as
%      fields.
%
%      (OPTIONAL INPUTS)
%
%      sensorType: a string to indicate the type of sensor to query to
%      establish start and end time intervals. For example 'gps' will query
%      all sensors whose name contains 'gps' somewhere in the name. Default
%      is to use 'GPS' sensors to establish start and end time intervals.
%
%      fid: a file ID to print results of analysis. If not entered, the
%      console (FID = 1) is used.
%
% OUTPUTS:
%
%      fixedDataStructure: a data structure to be analyzed that includes the following
%      fields:
%
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%
% EXAMPLES:
%
%     See the script: script_test_fcn_TimeClean_fixAlignSensorsToTime
%     for a full test suite.
%
% This function was written on 2023_06_29 by S. Brennan
% Questions or comments? sbrennan@psu.edu

% Revision history:
%
% 2025_11_30: sbrennan@psu.edu
% - Wrote the code originally


% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)

% Check if flag_max_speed set. This occurs if the fig_num variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
flag_max_speed = 0;
if (nargin==3 && isequal(varargin{end},-1))
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 0; % Flag to perform input checking
    flag_max_speed = 1;
else
    % Check to see if we are externally setting debug mode to be "on"
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 1; % Flag to perform input checking
    MATLABFLAG_DATACLEAN_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_DATACLEAN_FLAG_CHECK_INPUTS");
    MATLABFLAG_DATACLEAN_FLAG_DO_DEBUG = getenv("MATLABFLAG_DATACLEAN_FLAG_DO_DEBUG");
    if ~isempty(MATLABFLAG_DATACLEAN_FLAG_CHECK_INPUTS) && ~isempty(MATLABFLAG_DATACLEAN_FLAG_DO_DEBUG)
        flag_do_debug = str2double(MATLABFLAG_DATACLEAN_FLAG_DO_DEBUG);
        flag_check_inputs  = str2double(MATLABFLAG_DATACLEAN_FLAG_CHECK_INPUTS);
    end
end

% flag_do_debug = 1;

if flag_do_debug
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
    debug_fig_num = 999978; %#ok<NASGU>
else
    debug_fig_num = []; %#ok<NASGU>
end


%% check input arguments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                   _
%  |_   _|                 | |
%    | |  _ __  _ __  _   _| |_ ___
%    | | | '_ \| '_ \| | | | __/ __|
%   _| |_| | | | |_) | |_| | |_\__ \
%  |_____|_| |_| .__/ \__,_|\__|___/
%              | |
%              |_|
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (0==flag_max_speed)
    if flag_check_inputs
        % Are there the right number of inputs?
        narginchk(1,3);
    end
end

% Does the user want to specify the sensorType?
sensorType = ''; % 'GPS';
if 2 <= nargin
    temp = varargin{1};
    if ~isempty(temp)
        sensorType = temp;
    end
end


% Does the user want to specify the fid?
% Check for user input
fid = 0; % Default case is to NOT print to the console
if (0==flag_max_speed)
    if 3 == nargin
        temp = varargin{end};
        if ~isempty(temp)
            % Check that the FID works
            try
                temp_msg = ferror(temp); %#ok<NASGU>
                % Set the fid value, if the above ferror didn't fail
                fid = temp;
            catch ME
                warning('on','backtrace');
                warning('User-specified FID does not correspond to a file. Unable to continue.');
                throwAsCaller(ME);
            end
        end
    end
end

flag_do_plots = 0;  % % Flag to plot the final results


%% Main code starts here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Pull all Trigger_Time values

[allTriggerTimes, allSensorNames]         = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(dataStructure, 'Trigger_Time',sensorType);
[allCentiSeconds, ~]         = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(dataStructure, 'centiSeconds',sensorType);

% Initialize the result:
fixedDataStructure = dataStructure;

% Loop through the fields, searching for ones that have "GPS" in their name
for ith_sensor = 1:length(allSensorNames)

    % Grab the sensor name
    thisSensorName = allSensorNames{ith_sensor};

    % Grab the triggerTimes
    thisSensorTriggerTime = allTriggerTimes{ith_sensor};

    % Grab the centiSeconds
    thisCentiSeconds = allCentiSeconds{ith_sensor};

    if 0~=fid
        fprintf(fid,'\t Checking that all data in sensor %d of %d, %s, has the length %.0d of Trigger_Time\n',ith_sensor,length(allSensorNames),thisSensorName, length(thisSensorTriggerTime));
    end

    % Which time data to use
    GPS_time_data = dataStructure.(thisSensorName).GPS_Time;
    GPSfromROS_time_data = dataStructure.(thisSensorName).GPSfromROS_Time;
    if ~all(isnan(GPS_time_data))
        thisSensorGPSTimeEstimate = GPS_time_data;
    else
        thisSensorGPSTimeEstimate = GPSfromROS_time_data;
    end

    % Calculate indices that meet start/end criteria
    timeTolerance = allCentiSeconds{ith_sensor}/2*0.01;
    startTime = thisSensorTriggerTime(1)-timeTolerance;
    endTime   = thisSensorTriggerTime(end)+timeTolerance;
    indexStart = find(thisSensorGPSTimeEstimate>=startTime,1,'first');
    indexEnd   = find(thisSensorGPSTimeEstimate<=endTime,1,'last');
    desiredNsamples = length(thisSensorTriggerTime);
    actualNsamples = indexEnd-indexStart+1;
    maxActual = length(thisSensorGPSTimeEstimate);

    % Fill in default indices
    defaultIndices = fcn_INTERNAL_fillDefaultIndices(desiredNsamples, indexStart, maxActual);


    if fid>0
        fprintf(fid,'\t\t Summary of results:\n');
        fprintf(fid,'\t\t Desired start time:  %.4f\n',thisSensorTriggerTime(1));
        fprintf(fid,'\t\t Actual start time:   %.4f\n',thisSensorGPSTimeEstimate(indexStart));
        fprintf(fid,'\t\t Desired end time:    %.4f\n',thisSensorTriggerTime(end));
        fprintf(fid,'\t\t Actual end time:     %.4f\n',thisSensorGPSTimeEstimate(indexEnd));
        fprintf(fid,'\t\t Desired samples:     %.0d\n',desiredNsamples);
        fprintf(fid,'\t\t Actual samples:      %.0d\n',actualNsamples);
    end

    if desiredNsamples~=actualNsamples
        if fid>0
            fprintf(fid,'\t\t Sample count mismatch requires alignment of GPSfromROS_Time to Trigger_Time\n');
            fprintf(fid,'\t\t Percentage difference: %.4f percent\n',(actualNsamples-desiredNsamples)/desiredNsamples*100);
        end

        if 1==1

            % First, find where the samples would land
            % Vq = interp1(X,V,Xq,METHOD,EXTRAPVAL)
            % rawIndicesMappingToTrigger = interp1(thisSensorTriggerTime,(1:desiredNsamples)', thisSensorGPSTimeEstimate,'nearest','extrap');
            rawIndicesMappingToTrigger = interp1(thisSensorGPSTimeEstimate(indexStart:indexEnd,1),(indexStart:indexEnd)', thisSensorTriggerTime,'nearest','extrap');

            timeDifferences = fcn_INTERNAL_updateTimeDifferences(thisSensorGPSTimeEstimate, thisSensorTriggerTime, rawIndicesMappingToTrigger);
            indexDifferences = diff(rawIndicesMappingToTrigger);

            if any(indexDifferences<0)
                error('Found situation where time increments are moving out of order. Unable to continue.\n');
            end

            % The following commented area tries to further refine the fit
            correctedIndicesMappingToTrigger = rawIndicesMappingToTrigger;
            if 1==0
                stallIndices = find(indexDifferences==0);
                jumpIndices = find(indexDifferences>1);
                allIndices = (1:desiredNsamples)';
                timeJumpIndices = find(abs(diff(timeDifferences))>(thisCentiSeconds*0.01/2));

                if 1==0
                    figure(4444);
                    clf;
                    plot(allIndices, timeDifferences,'b-','DisplayName','Time Differences');
                    hold on;
                    plot(stallIndices, timeDifferences(stallIndices,1),'r.','DisplayName','Index Stalls','MarkerSize',10);
                    plot(jumpIndices, timeDifferences(jumpIndices,1),'g.','DisplayName','Index Jumps','MarkerSize',10);
                    plot(timeJumpIndices, timeDifferences(timeJumpIndices,1),'co','DisplayName','Time Jumps','MarkerSize',5);
                    legend('Interpreter','none','Location','best');
                    xlim([0 1000]);

                end


                flagShowRanking = 0;

                timeJumpIndices = union(stallIndices,jumpIndices);

                deltaIndices = diff(correctedIndicesMappingToTrigger);

                % Confirm that can go from delta indices to predicted
                if 1==0
                    predictedIndices = fcn_INTERNAL_convertDeltaIndicesToIndices(deltaIndices, correctedIndicesMappingToTrigger(1));
                    assert(isequal(predictedIndices,correctedIndicesMappingToTrigger))
                end

                % At each point that the indices jump away from 1, either to 0
                % or above 1, check that this produces a better outcome

                for ith_timeJump = 1:length(timeJumpIndices)
                    if mod(ith_timeJump-1,100)==0
                        fprintf(1,'Fixing jump: %.0f of %.0f\n',ith_timeJump, length(timeJumpIndices));
                    end
                    thisJumpIndex = timeJumpIndices(ith_timeJump);

                    % Define index window to plot
                    startIndexForPlotting = max(thisJumpIndex-100,1);
                    endIndexForPlotting = min(desiredNsamples,thisJumpIndex+100);
                    indexRangeForPlotting = (startIndexForPlotting:endIndexForPlotting)';
                    indexRangeForTesting  = (thisJumpIndex:endIndexForPlotting)';

                    % Define the previous timeDifference
                    previousTimeDifference    = timeDifferences(thisJumpIndex);

                    % Find suggested index jump
                    thisIndex = correctedIndicesMappingToTrigger(thisJumpIndex);
                    nextIndex = correctedIndicesMappingToTrigger(thisJumpIndex+1);
                    suggestedIndexJump = nextIndex - thisIndex;

                    % Plot current options
                    if 1==flagShowRanking
                        figure(3333);
                        clf;
                        xline(thisJumpIndex,'Color',0.7*[1 1 1],'LineWidth',3,'DisplayName','Current Jump');
                        hold on;
                        yline(previousTimeDifference,'Color',0.3*[1 1 1],'LineWidth',3,'DisplayName','Previous Time Difference');
                        plot(indexRangeForPlotting, timeDifferences(indexRangeForPlotting),'b', 'LineWidth',5, 'DisplayName','Current plan');
                        legend('Interpreter','none','Location','best');
                    end


                    % Do perturbations around this jump
                    jumpsToTry = 0:suggestedIndexJump+1;
                    Njumps = length(jumpsToTry);
                    modifiedIndices = cell(Njumps,1);
                    modifiedTimeDiffs = cell(Njumps,1);
                    differencesFromCurrent = nan(Njumps,1);
                    for ith_jump = 1:Njumps
                        thisJump = jumpsToTry(ith_jump);

                        % Fill in delta indices
                        testDeltaIndices = deltaIndices;
                        testDeltaIndices(thisJumpIndex) = thisJump;

                        % Convert delta indices into indices
                        predictedIndices = fcn_INTERNAL_convertDeltaIndicesToIndices(testDeltaIndices, correctedIndicesMappingToTrigger(1));
                        testIndices = correctedIndicesMappingToTrigger;
                        testIndices(thisJumpIndex+1:end) = predictedIndices(thisJumpIndex+1:end);

                        testTimeDifferences = fcn_INTERNAL_updateTimeDifferences(thisSensorGPSTimeEstimate, thisSensorTriggerTime, testIndices);

                        thisTimeDifference = testTimeDifferences(thisJumpIndex+1);
                        if abs(thisTimeDifference)>(thisCentiSeconds*0.01)
                            thisTimeDifference = inf;
                        end


                        differencesFromCurrent(ith_jump,1) = abs(previousTimeDifference - thisTimeDifference);

                        modifiedIndices{ith_jump,1} = testIndices;
                        modifiedTimeDiffs{ith_jump,1} = testTimeDifferences;

                        if 1==flagShowRanking
                            figure(3333);
                            plot(indexRangeForTesting, testTimeDifferences(indexRangeForTesting),'-', 'LineWidth',3, 'DisplayName',sprintf('Jump of %.0f',thisJump));
                        end
                    end % Ends looping through options

                    [~,jumpToUse] = min(differencesFromCurrent);

                    correctedIndicesMappingToTrigger =  modifiedIndices{jumpToUse,1};
                    deltaIndices = diff(correctedIndicesMappingToTrigger);
                    timeDifferences = fcn_INTERNAL_updateTimeDifferences(thisSensorGPSTimeEstimate, thisSensorTriggerTime, correctedIndicesMappingToTrigger);


                    if 1==flagShowRanking
                        figure(3333);
                        plot(indexRangeForPlotting, timeDifferences(indexRangeForPlotting),'k', 'LineWidth',1, 'DisplayName','Winning vote');
                        pause(0.1);
                    end
                end % Ends for loop

                if 1==1
                    figure(4444);
                    plot(allIndices, timeDifferences,'g-','DisplayName','Time Differences');
                    xlim('auto');
                end

            end % Ends flag to try to improve fit

            indicesMappingToTrigger = correctedIndicesMappingToTrigger;
        else
            % Use a greedy algorithm to match times to each other.
            % VERY slow
            indicesMappingToTrigger = fcn_INTERNAL_greedyAlignTimes(thisSensorTriggerTime, thisSensorGPSTimeEstimate, thisCentiSeconds, fid);
        end

        % Check for repeated indices
        repeatedIndices = [diff(indicesMappingToTrigger); 1] ==0;

        % Loop through subfields
        original_vector_size = length(thisSensorGPSTimeEstimate);
        sensor_data = fixedDataStructure.(thisSensorName);
        subfieldNames = fieldnames(sensor_data);
        for i_subField = 1:length(subfieldNames)
            % Grab the name of the ith subfield
            subFieldName = subfieldNames{i_subField};

            if ~iscell(sensor_data.(subFieldName)) % Is it a cell? If yes, skip it
                if length(sensor_data.(subFieldName)) ~= 1 % Is it a scalar? If yes, skip it
                    % It's an array, make sure it has right length
                    if isequal(size(sensor_data.(subFieldName),1),original_vector_size)
                        if strcmp(thisSensorName,'LIDAR_Sick_Rear')
                            warning('on','backtrace');
                            warning('SICK lidar data processing not yet tested.');
                        else
                            % Resize the data to exact same indicies as trimmed
                            % GPS_Time field, to align with the Trigger_Time
                            fixedDataStructure.(thisSensorName).(subFieldName) = sensor_data.(subFieldName)(indicesMappingToTrigger,:);
                            fixedDataStructure.(thisSensorName).(subFieldName)(repeatedIndices,:) = nan;
                        end
                    end
                end
            end

        end % Ends for loop through the subfields

    else
        % The time data exactly matches expected length!
        indicesMappingToTrigger = defaultIndices; %#ok<NASGU>
    end



end

%% Plot the results (for debugging)?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_do_plots

    % Nothing to plot

end

if flag_do_debug
    fprintf(1,'\nENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function




%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%§

%% fcn_INTERNAL_findCommonStartEndTime
function centitime_all_sensors_from_GPS_Time = fcn_INTERNAL_findCommonStartEndTime(dataStructure, sensorType, stringFirstOrLast, sensor_names_centiSeconds, max_sampling_period_centiSeconds, fid)

if strcmpi(stringFirstOrLast,'first')
    entryLocation = 'first_row';
else
    entryLocation = 'last_row';
end

[cell_array_GPS_Time, sensor_names_GPS_Time]         = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(dataStructure, 'GPS_Time',sensorType,entryLocation);

% Confirm that both results are identical
if ~isequal(sensor_names_GPS_Time,sensor_names_centiSeconds)
    warning('on','backtrace');
    warning('Sensors were found that were missing either GPS_Time or centiSeconds.');
    error('Sensors were found that were missing either GPS_Time or centiSeconds. Unable to calculate Trigger_Times.');
end

% Convert GPS_Time to a column matrix
array_GPS_Time = cell2mat(cell_array_GPS_Time)';


% Find when each sensor's start/end time lands on this centiSecond
% value, rounding up or down
if strcmpi(stringFirstOrLast,'first')
    all_times_centiSeconds = ceil(100*array_GPS_Time/max_sampling_period_centiSeconds)*max_sampling_period_centiSeconds;
    centitime_all_sensors_from_GPS_Time = max(all_times_centiSeconds);
else
    all_times_centiSeconds = floor(100*array_GPS_Time/max_sampling_period_centiSeconds)*max_sampling_period_centiSeconds;
    centitime_all_sensors_from_GPS_Time = min(all_times_centiSeconds);

end


% Warn if max/min are WAY off (like more than 1 second)
if (max(all_times_centiSeconds)-min(all_times_centiSeconds))>100
    warning('on','backtrace');
    warning('The %s times on different sensors appear to have GPS_Time that is untrimmed to same value.', stringFirstOrLast);
    error('The %s times on different sensors appear to be untrimmed to same value. The Trigger_Time calculations will give incorrect results if the data are not trimmed first.', stringFirstOrLast);
end


% Show the results?
if fid
    longestStringLength = 0;
    for ith_name = 1:length(sensor_names_GPS_Time)
        if length(sensor_names_GPS_Time{ith_name})>longestStringLength
            longestStringLength = length(sensor_names_GPS_Time{ith_name});
        end
    end
    fprintf(fid,'\t \t Summarizing %s times: \n', stringFirstOrLast);
    sensor_title_string = fcn_DebugTools_debugPrintStringToNCharacters('Sensors:',longestStringLength);
    posix_title_string = fcn_DebugTools_debugPrintStringToNCharacters('Posix Time (sec since 1970):',29);
    datetime_title_string = fcn_DebugTools_debugPrintStringToNCharacters('Date Time:',25);
    fprintf(fid,'\t \t %s \t %s \t %s \n',sensor_title_string,posix_title_string,datetime_title_string);
    for ith_data = 1:length(sensor_names_GPS_Time)
        sensor_data_string = fcn_DebugTools_debugPrintStringToNCharacters(sensor_names_GPS_Time{ith_data},longestStringLength);
        posix_data_string = fcn_DebugTools_debugPrintStringToNCharacters(sprintf('%.6f',array_GPS_Time(ith_data)),29);
        time_in_datetime = datetime(array_GPS_Time(ith_data),'convertfrom','posixtime','format','yyyy-MM-dd HH:mm:ss.SSS');

        time_string = sprintf('%s',time_in_datetime);
        datetime_data_string = fcn_DebugTools_debugPrintStringToNCharacters(time_string,25);
        fprintf(fid,'\t \t %s \t %s \t %s \n',sensor_data_string,posix_data_string,datetime_data_string);
    end
    finalresults_title_string = fcn_DebugTools_debugPrintStringToNCharacters(sprintf('Calculated %s centiTime:',stringFirstOrLast),longestStringLength);
    finalresults_number_string = fcn_DebugTools_debugPrintStringToNCharacters(sprintf('%.0f',centitime_all_sensors_from_GPS_Time),29);
    fprintf(fid,'\t \t %s \t %s \n',finalresults_title_string,finalresults_number_string);
    fprintf(fid,'\n');
end
end % Ends fcn_INTERNAL_findCommonStartEndTime


%% fcn_INTERNAL_greedyAlignTimes
function indicesMappingToTrigger = fcn_INTERNAL_greedyAlignTimes(thisSensorTriggerTime, thisSensorGPSTimeEstimate, thisCentiSeconds, fid)

desiredNsamples = length(thisSensorTriggerTime);
actualNsamples = length(thisSensorGPSTimeEstimate);

% Use a greedy algorithm to match times to each other.
% VERY slow
indicesMappingToTrigger = nan(desiredNsamples,1);
remainingIndicies = (1:actualNsamples)';
for ith_time = 1:desiredNsamples
    if fid>0 && desiredNsamples>10000
        if mod(ith_time-1,10000)==0
            fprintf(fid,'\t\tFixing index: %.0d of %.0d\n', ith_time, desiredNsamples);
        end
    end
    thisTime = thisSensorTriggerTime(ith_time,1);
    remainingUnmatchedIndices = remainingIndicies(~isnan(remainingIndicies));
    remainingUnmatchedTimes = thisSensorGPSTimeEstimate(~isnan(remainingIndicies));

    % Find minimum difference
    timeDifferences = (remainingUnmatchedTimes-thisTime).^2;
    [minTimeSquared, minIndex] = min(timeDifferences);

    minTime = real(minTimeSquared^0.5);

    if abs(minTime)<(thisCentiSeconds*0.01)

        actualIndex = remainingUnmatchedIndices(minIndex,1);

        % Save mapping
        indicesMappingToTrigger(ith_time,1) = actualIndex;

        % Remove this index from the search list
        remainingIndicies(actualIndex) = nan;
    end
end


end % Ends fcn_INTERNAL_greedyAlignTimes



%% fcn_INTERNAL_fillDefaultIndices
function defaultIndices = fcn_INTERNAL_fillDefaultIndices(desiredNsamples, actualIndexStart, maxAllowableIndex)

% Creates a vector of indicies that starts at an offset and fills the
% remainder of an array, up to desiredNsamples. Will not give values larger
% than actualNsamples.



% Fill in default indices
defaultIndices = (1:desiredNsamples)';

% Add offset. Remember to subtract 1, since an actualIndexStart of 1 means to add 0.
defaultIndices = defaultIndices + actualIndexStart-1;

% Cap values at maxAllowableIndex
defaultIndices = min(defaultIndices, maxAllowableIndex);

end % Ends fcn_INTERNAL_fillDefaultIndices

%% fcn_INTERNAL_updateTimeDifferences
function timeDifferences = fcn_INTERNAL_updateTimeDifferences(thisSensorGPSTimeEstimate, thisSensorTriggerTime, rawIndicesMappingToTrigger)
predictedTriggerTime = thisSensorGPSTimeEstimate(rawIndicesMappingToTrigger,1);
timeDifferences = thisSensorTriggerTime - predictedTriggerTime;
end % Ends fcn_INTERNAL_updateTimeDifferences



%% fcn_INTERNAL_convertDeltaIndicesToIndices
function predictedIndices = fcn_INTERNAL_convertDeltaIndicesToIndices(deltaIndices, startIndex)
predictedIndices = [0; cumsum(deltaIndices)] + startIndex;
end