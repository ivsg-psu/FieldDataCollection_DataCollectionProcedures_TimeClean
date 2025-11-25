function trimmed_dataStructure = fcn_TimeClean_trimDataToCommonStartEndGPSTimes(dataStructure,varargin)

% fcn_TimeClean_trimDataToCommonStartEndGPSTimes
% Trims all sensor data so that all start and end at the same GPS_Time
% values, and fills in missing values that do not align with the time
% sequence. If the field_name is 'GPS_Time', all the data in the structure
% is re-sorted to match. Otherwise, for any other "time" type field names,
% the data is unchanged.
%
% The method this is done is to:
% 1. Pull out the GPS_Time field from all GPS-tagged sensors
% 2. Find the start/end values for each. Take the maximum start time and
%    minimum end time and assign these to the global start and end times.
% 3. Crop all data in all sensors to these global start and end times
%
% FORMAT:
%
%      trimmed_dataStructure = fcn_TimeClean_trimDataToCommonStartEndGPSTimes(dataStructure, (field_name), (sensors_to_check), (fill_type), (fid))
%
% INPUTS:
%
%      dataStructure: a data structure to be analyzed that includes the following
%      fields:
%
%      (OPTIONAL INPUTS)
%
%      field_name: the field to be checked, as a string. If left empty,
%      default is 'GPS_Time'.
%
%      sensors_to_check: a string listing the sensors to check. For
%      example, 'GPS' will check every sensor in the dataStructure whose
%      name contains 'GPS'. Default is empty, which checks all sensors.
%
%      fill_type:
%
%           0: Fill with NaN values (default)
%
%           1: Fill with reference time sequence for GPS-labeled sensors
%           only
%
%      fid: a file ID to print results of analysis. If not entered, the
%      console (FID = 1) is used.
%
% OUTPUTS:
%
%      trimmed_dataStructure: a data structure to be analyzed that includes the following
%      fields:
%
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%
% EXAMPLES:
%
%     See the script: script_test_fcn_TimeClean_trimDataToCommonStartEndGPSTimes
%     for a full test suite.
%
% This function was written on 2023_06_19 by S. Brennan
% Questions or comments? sbrennan@psu.edu

% Revision history:
%
% 2023_06_12: sbrennan@psu.edu
% -- wrote the code originally
% 
% 2023_06_24 - sbrennan@psu.edu
% -- added fcn_INTERNAL_checkIfFieldInAnySensor and test case in script
% 
% 2024_09_28 - S. Brennan
% -- updated the debug flags area
% -- fixed bug where offending sensor is set wrong
% -- fixed fid bug where it is used in debugging
% 
% 2024_11_22 - sbrennan@psu.edu
% -- major rewrite to use reference time sequence instead of start/end
% trimming
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - Changed in-use function name
%   % * From: fcn_LoadRawDataTo+MATLAB_pullDataFromFieldAcrossAllSensors
%   % * To: fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll



% Check if flag_max_speed set. This occurs if the fig_num variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
flag_max_speed = 0;
if (nargin==5 && isequal(varargin{end},-1))
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
        narginchk(1,5);
    end
end

% Does the user want to specify the field_name?
field_name = 'GPS_Time';
if 2 <= nargin
    temp = varargin{1};
    if ~isempty(temp)
        field_name = temp;
    end
end

% Does the user want to specify the sensors_to_check?
sensors_to_check = '';
if 3 <= nargin
    temp = varargin{2};
    if ~isempty(temp)
        sensors_to_check = temp;
    end
end


% Does the user want to specify the fill_type?
fill_type = 0;
if 4 <= nargin
    temp = varargin{3};
    if ~isempty(temp)
        fill_type = temp;
    end
end


% Does the user want to specify the fid?
% Check for user input?
fid = 0;
if (0==flag_max_speed)

    if 5 <= nargin
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

%% Tell user what we are doing?
if 0~=fid
    if isempty(sensors_to_check)
        summary_name = 'all';
    else
        summary_name = sensors_to_check;
    end
    fprintf(fid,'Checking consistency of start and end %s across %s sensors:\n', field_name, summary_name);
end


% The method this is done is to:
% 1. Pull out the GPS_Time field from all GPS-tagged sensors
% 2. Find the start/end values for each. Take the maximum start time and
%    minimum end time and assign these to the global start and end times.
% 3. Crop all data in all sensors to these global start and end times

%% Step 1: Pull out the GPS_Time field from all GPS-tagged sensors
% Note, this can be GPS time, or a GPS surrogate time

% Produce a list of all the sensors that would have GPS data
[GPS_Time_data_raw, GPS_Time_sensorNames] =  fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(dataStructure, 'GPS_Time','GPS');
[GPS_centiSeconds_raw,~] =  fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(dataStructure, 'centiSeconds','GPS');
[GPS_Time_start_raw, ~] =  fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(dataStructure, 'GPS_Time','GPS','first_row');
[GPS_Time_end_raw, ~] =  fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(dataStructure, 'GPS_Time','GPS','last_row');

% Produce a list of all the sensors time data we need
[SENSOR_Time_data_raw,  SENSOR_Time_sensorNames] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(dataStructure, field_name, 'GPS');
% [sensorsToTrim_centiSeconds,~]                   = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(dataStructure, 'centiSeconds',sensors_to_check);
[SENSOR_Time_start_raw, ~] =  fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(dataStructure, field_name, 'GPS','first_row');
assert(isequal(GPS_Time_sensorNames,SENSOR_Time_sensorNames)); % Make sure the sensor time sensors match the GPS time sensors

N_referenceSensors = length(GPS_Time_sensorNames);

% For debugging
% The times are usually in UTC seconds, which are VERY hard to read as they
% are measured in millions and billions. To make the code easier to debug,
% we subtract off a common value from all the time data, called the
% debuggingOffset. This is usually arbitrary - the first time point in the
% first GPS sensor's GPS_Time data
if 1==1
    debuggingOffset = ceil(GPS_Time_data_raw{1}(1));
else
    debuggingOffset = 0;
end

% Fix all the data to remove offsets
GPS_Time_data = cell(N_referenceSensors,1);
GPS_centiSeconds = cell(N_referenceSensors,1);
GPS_Time_start = cell(N_referenceSensors,1);
GPS_Time_end = cell(N_referenceSensors,1);
GPS_Time_referenceLength = nan(N_referenceSensors,1);
SENSOR_Time_data = cell(N_referenceSensors,1);
SENSOR_Time_start = cell(N_referenceSensors,1);

for ith_sensor = 1:N_referenceSensors
    GPS_Time_data{ith_sensor}    = GPS_Time_data_raw{ith_sensor}    - debuggingOffset;
    GPS_centiSeconds{ith_sensor} = GPS_centiSeconds_raw{ith_sensor};
    GPS_Time_start{ith_sensor}   = GPS_Time_start_raw{ith_sensor}   - debuggingOffset;
    GPS_Time_end{ith_sensor}     = GPS_Time_end_raw{ith_sensor}     - debuggingOffset;
    SENSOR_Time_data{ith_sensor} = SENSOR_Time_data_raw{ith_sensor} - debuggingOffset;
    SENSOR_Time_start{ith_sensor} = SENSOR_Time_start_raw{ith_sensor} - debuggingOffset;
    GPS_Time_referenceLength(ith_sensor,1) = length(GPS_Time_data_raw{ith_sensor});
end

% Convert cell arrays to matricies
GPS_Time_startVector = [GPS_Time_start{:}]';
GPS_Time_endVector   = [GPS_Time_end{:}]';

%% Step 2. Find the start/end values for GPS data in all GPS sensors
% Take the maximum start time and minimum end time and assign these to the
% global start and end times.
[allGPSSensor_GPS_startTime_Seconds, allGPSSensor_GPS_endTime_Seconds] = fcn_INTERNAL_extractStartStopTimes(GPS_Time_sensorNames, GPS_centiSeconds, GPS_Time_startVector, GPS_Time_endVector, fid);
allGPSsensor_GPS_time_duration = allGPSSensor_GPS_endTime_Seconds-allGPSSensor_GPS_startTime_Seconds;
fprintf(fid,'\t The GPS_Time that contains all reference sensors has the following range (with offset: %.0f seconds): \n',debuggingOffset);
fprintf(fid,'\t\t Start Time (UTC seconds): %.3f\n',allGPSSensor_GPS_startTime_Seconds);
fprintf(fid,'\t\t End Time   (UTC seconds): %.3f\n',allGPSSensor_GPS_endTime_Seconds);


%% Step 3: determine the offset of the user-requested time field relative to GPS_Time
% Any non-GPS time does not have the same origin as the GPS time, so if the
% user is correcting something other than GPS time, we need to keep track of that offset.
if strcmp(field_name,'GPS_Time')
    offsetSensorRelativeToGPS = 0;
else
    offsetSensorRelativeToGPS = mean([SENSOR_Time_start{:}]) - mean([GPS_Time_start{:}]);
end

%% Step 4: Get indicies map for each sensor
% Loop through the sensors, finding the index map for each sensor
% The index map is a list of integers of length that exactly matches the
% centiSecond sampling time to completely cover the time interval from
% start time to end time. The integers correspond to the indicies in the
% time data for that sensor's time data that correspond to the reference.
% NaN values are used to fill times in the reference map that are not
% filled.
%
% The index map defines how all the data in the sensor - not just the time
% - is reshuffled so that, when the time is updated, the data are updated
% accordingly. Note: this means that data can only be shifted in a sensor
% that has an absolute reference. Typically, these are sensors containing
% GPS_Time, or after processing, sensors containing GPSfromROS_Time.
%
% For example, if the reference time is 0 to 1 sampled every 0.2 seconds,
% but the sensor was only measured at 0.2 and 0.4 seconds in sensor
% indicies 1 and 2 respectively, then the index map would be:
%     .0:  NaN
%     .1:  NaN
%     .2:  1
%     .3:  NaN
%     .4:  2
%     .5:  NaN
%     .6:  NaN
%     .7:  NaN
%     .8:  NaN
%     .9:  NaN
%    1.0:  NaN


if 0~=fid
    fprintf(fid,'\t Calculating index mapping for %s across these sensors: \n',field_name);
end

% Initialize the structures and arrays
trimmed_dataStructure = dataStructure;
indiciesLocalUsed_InReference = cell(N_referenceSensors,1);
replacement_reference         = cell(N_referenceSensors,1);

for ith_sensor = 1:N_referenceSensors
    % Grab the sensor subfield name
    sensor_name             = GPS_Time_sensorNames{ith_sensor};
    sensor_centiSeconds     = GPS_centiSeconds{ith_sensor};
    sensor_time_in_GPS_time = SENSOR_Time_data{ith_sensor} - offsetSensorRelativeToGPS;

    fprintf(fid,'\t Sensor: %s \n',sensor_name);
    fprintf(fid,'\t\t Sorted?: %.0f\n',~any(diff(sensor_time_in_GPS_time)<=0));

    indiciesLocalUsed_InReference{ith_sensor} = fcn_INTERNAL_findIndexMapping(allGPSSensor_GPS_startTime_Seconds, allGPSsensor_GPS_time_duration, sensor_centiSeconds, sensor_time_in_GPS_time, fid);
    replacement_reference{ith_sensor} = fcn_INTERNAL_mapSensorIndicies(allGPSSensor_GPS_startTime_Seconds, sensor_time_in_GPS_time, sensor_centiSeconds, indiciesLocalUsed_InReference{ith_sensor}, allGPSsensor_GPS_time_duration, fill_type, debuggingOffset, fid);
    trimmed_dataStructure.(sensor_name).(field_name) = replacement_reference{ith_sensor} + offsetSensorRelativeToGPS + debuggingOffset;

end


%% Step 5: If this is GPS_Time, loop through the sensors, creating blanks for each
if strcmp(field_name,'GPS_Time')
    for ith_sensor = 1:N_referenceSensors
        % Grab this sensor's data
        sensor_name                          = GPS_Time_sensorNames{ith_sensor};
        sensor_centiSeconds                  = GPS_centiSeconds{ith_sensor};
        sensor_data                          = trimmed_dataStructure.(sensor_name);
        sensor_indiciesLocalUsed_InReference = indiciesLocalUsed_InReference{ith_sensor};
        lengthReference                      = GPS_Time_referenceLength(ith_sensor,1);

        % Tell user what we are doing
        if 0~=fid
            fprintf(fid,'\t Trimming sensor %d of %d to have correct start and end %s values: %s\n',ith_sensor,length(GPS_Time_sensorNames),field_name, sensor_name);
        end

        trimmed_dataStructure = fcn_INTERNAL_mapAllFieldsInSensor(allGPSSensor_GPS_startTime_Seconds, lengthReference, trimmed_dataStructure, sensor_name, sensor_centiSeconds, sensor_data, sensor_indiciesLocalUsed_InReference, field_name, allGPSsensor_GPS_time_duration, debuggingOffset, fid);

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
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
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

%%
function [allSensor_startTime_Seconds, allSensor_endTime_Seconds] = fcn_INTERNAL_extractStartStopTimes(GPS_Time_sensorNames, GPS_centiSeconds, GPS_Time_startVector, GPS_Time_endVector, fid)
% Loop through the fields, searching for ones that have "GPS" in their
% name, and extract the start and end
N_GPSsensors = length(GPS_Time_sensorNames);
start_times_centiSeconds = zeros(N_GPSsensors,1);
end_times_centiSeconds   = zeros(N_GPSsensors,1);
for i_data = 1:N_GPSsensors
    % Grab the sensor subfield name
    sensor_name       = GPS_Time_sensorNames{i_data};
    sensor_centiSeconds = GPS_centiSeconds{i_data};

    if 0~=fid
        fprintf(fid,'\t Checking sensor %d of %d: %s\n',i_data,length(GPS_Time_sensorNames),sensor_name);
    end

    start_times_centiSeconds(i_data,1) = round(100*GPS_Time_startVector(i_data,1)/sensor_centiSeconds)*sensor_centiSeconds;
    end_times_centiSeconds(i_data,1)   = round(100*GPS_Time_endVector(i_data,1) /sensor_centiSeconds)*sensor_centiSeconds;
end



highest_start_time_centiSeconds = max(start_times_centiSeconds);
lowest_end_time_centiSeconds   = min(end_times_centiSeconds);

% Make sure we choose a time that all the sensors CAN start at. We round
% start seconds up to nearest second, and end seconds down to nearest second.
allSensor_startTime_Seconds = ceil(highest_start_time_centiSeconds*0.01);
allSensor_endTime_Seconds = floor(lowest_end_time_centiSeconds*0.01);


% THE COMMENTED AREA BELOW DOES A MORE REFINED CALCULATION
% % Make sure we choose a time that all the sensors CAN start at. For
% % example, if one sensor is 10Hz and another is 20 Hz, we cannot use 3.05
% % seconds as a start time because only the 20Hz sensor lands on this. We
% % have to find a start time that they all land on, for example 3.10 seconds.
% loop_iterations = 1;
% while ~all(mod(master_start_time_centiSeconds,sensor_centiSeconds)==0)
%     loop_iterations = loop_iterations+1;
%     master_start_time_centiSeconds = master_start_time_centiSeconds + min(sensor_centiSeconds);
%     if loop_iterations>100
%         error('Unable to lock GPS signals to a common start time');
%     end
% end
%
% loop_iterations = 1;
% while ~all(mod(master_end_time_centiSeconds,sensor_centiSeconds)==0)
%     loop_iterations = loop_iterations+1;
%     master_end_time_centiSeconds = master_end_time_centiSeconds - min(sensor_centiSeconds);
%     if loop_iterations>100
%         error('Unable to lock GPS signals to a common end time');
%     end
% end
%
% % Convert back into normal seconds
% allSensor_startTime_Seconds = master_start_time_centiSeconds*0.01;
% allSensor_endTime_Seconds = master_end_time_centiSeconds*0.01;

% Check for obvious errors
if allSensor_startTime_Seconds>=allSensor_endTime_Seconds
    warning('on','backtrace');
    warning('\n\nAn error will be thrown due to bad GPS timings. The following table should assist in debugging this issue: \n');
    fprintf('Sensor \t\t\t\t Start time: \t End_time\n');
    for ith_sensor = 1:length(start_times_centiSeconds)
        fprintf('%s \t %d  \t %d \n',GPS_Time_sensorNames{ith_sensor}, start_times_centiSeconds(ith_sensor),end_times_centiSeconds(ith_sensor));
    end

    fprintf('Master start time (seconds): \t%d\n',allSensor_startTime_Seconds);
    fprintf('Master end time (seconds):   \t%d\n',allSensor_endTime_Seconds);

    fprintf('\n\nTable reshifted by start time:\n');
    fprintf('Sensor \t\t\t\t Start time: \t End_time\n');
    for ith_sensor = 1:length(start_times_centiSeconds)
        fprintf('%s \t %d  \t %d \n',GPS_Time_sensorNames{ith_sensor}, start_times_centiSeconds(ith_sensor)-allSensor_startTime_Seconds*100,end_times_centiSeconds(ith_sensor)-allSensor_startTime_Seconds*100);
    end


    fprintf('\n\nEach sensor shifted by its own start time:\n');
    fprintf('Sensor \t\t\t\t Start time: \t End_time\n');
    for ith_sensor = 1:length(start_times_centiSeconds)
        fprintf('%s \t %d  \t %d \n',...
            GPS_Time_sensorNames{ith_sensor}, ...
            start_times_centiSeconds(ith_sensor)-start_times_centiSeconds(ith_sensor),...
            end_times_centiSeconds(ith_sensor)-start_times_centiSeconds(ith_sensor));
    end

    error('Unable to synchronize GPS signals because one GPS sensor has a starting GPS_Time field that seems to "start" after another GPS sensor recording ended! This is not physically possible if the sensors are running at the same time.');
end
end

%%
function indiciesLocalUsedInReference = fcn_INTERNAL_removeOverlaps(indiciesLocalUsedInReference, count_of_data_in_reference_time, indiciesOverlap, overlaps, zeroIndicies, local_sensor_centiTime_unrounded, reference_centisecond_sequence, fid)
% This function looks for indicies where there are overlaps, and finds
% "nearby" holes where these indicies can be filled. It then shifts the
% data so that the overlap is removed, causing the data to shift into the
% holes.

flag_do_debug = 0;

Npoints = length(count_of_data_in_reference_time);

% Try to fix at each index
for ith_overlap = 1:length(indiciesOverlap)
    % Which index, in the reference time vector, are we
    % checking? This is the location where more than one entry
    % was found.
    thisOverlapIndex = indiciesOverlap(ith_overlap);

    % Tell user what is happening

    if  1==flag_do_debug
        NprintsNearby = 10;
        beforeIndex = max(thisOverlapIndex-NprintsNearby,1);

        maxLength = min([Npoints length(indiciesLocalUsedInReference) length(count_of_data_in_reference_time) length(reference_centisecond_sequence) length(local_sensor_centiTime_unrounded)]);
        afterIndex  = min(thisOverlapIndex+NprintsNearby,maxLength);
        indicies_to_print = beforeIndex:afterIndex;

        fullTable = [indicies_to_print' indiciesLocalUsedInReference(indicies_to_print,1) count_of_data_in_reference_time(indicies_to_print,1) reference_centisecond_sequence(indicies_to_print,1) local_sensor_centiTime_unrounded(indicies_to_print,1)];

        fprintf(fid,'\t\t Sensor fails overlap test at index: %.0d!', thisOverlapIndex);
        header_strings = [{'Index'}, {'indiciesLocalUsedInReference'}, {'count_in_reference'},{'reference_centisecond'},{'local_centisecond'}];
        formatter_strings = [{'%.0d'},{'%.0f'},{'%.0f'},{'%.5f'},{'%.5f'}];
        N_chars = 40; % All columns have same number of characters

        table_data = fullTable;
        % table_data = fullTable(beforeIndex:afterIndex,:);

        fcn_DebugTools_debugPrintTableToNCharacters(table_data, header_strings, formatter_strings,N_chars);
    end


    % Find nearby zero overlaps
    flag_use_closest = 0;
    if ~isempty(zeroIndicies)
        % Grab the overlaps - there should be N of them where N is the
        % count
        N_overlaps = count_of_data_in_reference_time(thisOverlapIndex);
        overlappingIndicies = overlaps{thisOverlapIndex};
        assert(length(overlappingIndicies)==N_overlaps);

        % Find all zero overlaps within 10 indexes of current value
        nearbyZeroIndicies_Indexed = intersect(find(zeroIndicies>=thisOverlapIndex-10),find(zeroIndicies<=thisOverlapIndex+10));
        nearbyZeroIndicies = zeroIndicies(nearbyZeroIndicies_Indexed,:);

        % Are there enough nearby indicies to absorb overlaps?
        if length(nearbyZeroIndicies)>=(N_overlaps-1)
            % Find how close, in index spacing, the zeros are to the
            % current overlap index
            distancesToZeros = abs(thisOverlapIndex-nearbyZeroIndicies);
            [~,closestZeros] = sort(distancesToZeros);
            zerosToFill = nearbyZeroIndicies(closestZeros(1:N_overlaps-1));

            % Now, take all the zeros and the surplus indicies and find the
            % range of indicies that will be "smoothed"
            allIndicies = [thisOverlapIndex; zerosToFill];
            indexMinimum = min(allIndicies);
            indexMaximum = max(allIndicies);
            index_range_to_fill = (indexMinimum:indexMaximum)';

            % Figure out what goes into the fill spots
            old_values = indiciesLocalUsedInReference(index_range_to_fill);
            good_old_values = old_values(~isnan(old_values));
            values_to_fill = union(good_old_values,overlappingIndicies);

            % Make sure length of values to fill equals the indicies length
            assert(length(values_to_fill)==length(index_range_to_fill));

            % Update the indicies to finish the smoothing, and update the
            % count
            indiciesLocalUsedInReference(index_range_to_fill) = values_to_fill;
            count_of_data_in_reference_time(indexMinimum:indexMaximum) = 1;

            % Keep only the zero indicies that were NOT filled
            zeroIndicies = setdiff(zeroIndicies,zerosToFill);

            % For debugging
            if 1==0
                disp([before_indiciesLocalUsedInReference after_indiciesLocalUsedInReference]);
            end


        else
            % Zero is too far away, use closest time in
            % interval
            flag_use_closest = 1;
        end
    else
        % There are no zero overlap areas anywhere in the data. Use
        % closest!
        flag_use_closest = 1;
    end

    if 1==flag_use_closest
        % This section finds and keeps "closest" index of
        % choices.

        indicies_at_overlap = overlaps{thisOverlapIndex};

        timesToTest = local_sensor_centiTime_unrounded(indicies_at_overlap,1);
        thisTime = reference_centisecond_sequence(thisOverlapIndex,1);

        timeDistances = thisTime-timesToTest;
        [~,bestTimeToUse] = min(abs(timeDistances));
        bestIndex = indicies_at_overlap(bestTimeToUse);

        % Save results
        before_indiciesLocalUsedInReference = indiciesLocalUsedInReference;
        indiciesLocalUsedInReference(thisOverlapIndex,1) = bestIndex;
        after_indiciesLocalUsedInReference = indiciesLocalUsedInReference;
        count_of_data_in_reference_time(thisOverlapIndex,1) = 1;


        % For debugging
        if 1==1
            disp([before_indiciesLocalUsedInReference after_indiciesLocalUsedInReference]);
        end

    end

    if 1==flag_do_debug
        % fullTable = [(1:length(count_of_data_in_reference_time))' indiciesLocalUsedInReference count_of_data_in_reference_time reference_centisecond_sequence local_sensor_centiTime_unrounded];
        % fprintf(fid,'\n\t\t Sensor results after fix at index: %.0d', thisOverlapIndex);
        % 
        % header_strings = [{'Index'}, {'indiciesLocalUsedInReference'}, {'count_in_reference'},{'reference_centisecond'},{'local_centisecond'}];
        % formatter_strings = [{'%.0d'},{'%.0f'},{'%.0f'},{'%.5f'},{'%.5f'}];
        % N_chars = 40; % All columns have same number of characters
        % 
        % NprintsNearby = 10;
        % beforeIndex = max(thisOverlapIndex-NprintsNearby,1);
        % afterIndex  = min(thisOverlapIndex+NprintsNearby,Npoints);
        % 
        % table_data = fullTable(beforeIndex:afterIndex,:);
        % fcn_DebugTools_debugPrintTableToNCharacters(table_data, header_strings, formatter_strings,N_chars);

        NprintsNearby = 10;
        beforeIndex = max(thisOverlapIndex-NprintsNearby,1);

        maxLength = min([Npoints length(indiciesLocalUsedInReference) length(count_of_data_in_reference_time) length(reference_centisecond_sequence) length(local_sensor_centiTime_unrounded)]);
        afterIndex  = min(thisOverlapIndex+NprintsNearby,maxLength);
        indicies_to_print = beforeIndex:afterIndex;

        fullTable = [indicies_to_print' indiciesLocalUsedInReference(indicies_to_print,1) count_of_data_in_reference_time(indicies_to_print,1) reference_centisecond_sequence(indicies_to_print,1) local_sensor_centiTime_unrounded(indicies_to_print,1)];

        fprintf(fid,'\n\t\t Sensor results after fix at index: %.0d', thisOverlapIndex);
        header_strings = [{'Index'}, {'indiciesLocalUsedInReference'}, {'count_in_reference'},{'reference_centisecond'},{'local_centisecond'}];
        formatter_strings = [{'%.0d'},{'%.0f'},{'%.0f'},{'%.5f'},{'%.5f'}];
        N_chars = 40; % All columns have same number of characters


        % table_data = fullTable(beforeIndex:afterIndex,:);
        table_data = fullTable;
        fcn_DebugTools_debugPrintTableToNCharacters(table_data, header_strings, formatter_strings,N_chars);

    end


end
end

%% fcn_INTERNAL_findIndexMapping
function indiciesLocalUsedInReference = fcn_INTERNAL_findIndexMapping(allSensor_startTime_Seconds, allsensor_time_duration, sensor_centiSeconds, sensor_time, fid)

flag_doDebug = 1;
DEBUG_Nprints = 20;

% Determine the reference time sequence to check
reference_centisecond_sequence = fcn_INTERNAL_calculateReferenceTimeSequences(allsensor_time_duration, sensor_centiSeconds) + allSensor_startTime_Seconds*100;

% Shift all the data
sensor_centiTime_unrounded = (sensor_time)*100;

% Find the lengths of the data we are comparing
NreferenceTimes = length(reference_centisecond_sequence);


% % Trim the data to the same start/stop interval as the reference time
% % sequence. To do this, must be sure to include data that would otherwise
% % round to the correct start/stop values, so need to determine the rounding
% % interval which is half the sampling width. In other words, if the
% % sampling interval is 0.2 seconds and the start time is 0, then values
% % from -0.1 up to 0.1 could all be the same data as the 0 time sample. We
% % "catch" the end point by introducing a "nudge" in the time interval
% % we test. The good indicies - the ones that in the correct interval -
% % can be found by doing a element-wise multiplication of the 0 or 1
% % vectors that indicate if the element is in the correct interval.
% timeNudge = sensor_centiSeconds/2;
% goodDataIndicies = ...
%     (sensor_centiTime_unrounded >= reference_centisecond_start_time-timeNudge) .* ...
%     (sensor_centiTime_unrounded <= reference_centisecond_end_time+timeNudge);
% trimmed_local_sensor_centiTime_unrounded = sensor_centiTime_unrounded(find(goodDataIndicies),:);  %#ok<FNDSB>
sensor_centiTime_to_check = round(sensor_centiTime_unrounded/sensor_centiSeconds)*sensor_centiSeconds;

% For debugging
if 1==flag_doDebug
    fprintf('\n\n\t\t\tMatching the following reference to true values:\n');
    fprintf(1,'\t\t\t%s \t %s \t %s \n',...
        fcn_DebugTools_debugPrintStringToNCharacters('(index)',20),...
        fcn_DebugTools_debugPrintStringToNCharacters('(ref_centis)',20),...
        fcn_DebugTools_debugPrintStringToNCharacters(sprintf('(sensor_centis)'),20));
    for ith_index = 1:min(DEBUG_Nprints,NreferenceTimes)
        string1 = sprintf('%.0f', ith_index);
        string2 = sprintf('%.0f', reference_centisecond_sequence(ith_index));
        string3 = sprintf('%.0f', sensor_centiTime_to_check(ith_index));
        fprintf(1,'\t\t\t%s \t %s \t %s \n',...
            fcn_DebugTools_debugPrintStringToNCharacters(string1,20),...
            fcn_DebugTools_debugPrintStringToNCharacters(string2,20),...
            fcn_DebugTools_debugPrintStringToNCharacters(string3,20));
    end
end

% % Need to update the indicies that are used to that we know which ones
% % are within the correct interval. To do this, we need to keep track of
% % how the indicies shifted after trimming
% indiciesLocalShift = find(goodDataIndicies==1,1) - 1; % Find the shift in indicies



% This section "matches" the data to
% each other. A challenge with this is that, when the data
% glitches, it can shift entire data elements forward or backward.
% For example: if the data is normally coming in as:
%   1 2  3 4 5 6 7 8
% A glitch might make it come in like:
%   1 2 X 3 4 56 7 8
% Or like:
%   1 2 34 5 6 X 7 8
% where X is missing data and both 56 and 34 are time slots where
% there are 2 data points. To find if glitches might have occurred,
% we do one pass through he data to first count how many data
% elements are in each sampling window. If all are less than 2, we
% can do another pass to fill them in. If any are 2 or more, we
% have to figure out how to shift the "2" value. The only obvious
% way to shift to the 2 value is to look "nearby" the glitch
% location to see if there are any nearby zero values, and slide
% the data into those values. The steps below do this process.




% Loop through all the reference times, counting the number of times the
% integer values of the reference thisTime match the integer values
% of centiTime from the rounded local sensor's time.

% Initialize the matricies filled in this for loop
indiciesLocalUsedInReferenceWithOverlaps = nan(NreferenceTimes,1); % This holds the matching indicies
overlaps = cell(NreferenceTimes,1); % This holds indicies when there are more then 1 match
count_of_data_in_reference_time = zeros(NreferenceTimes,1); % This keeps track of how many matches were found for each of the reference times

for ith_time = 1:NreferenceTimes
    thisTime = reference_centisecond_sequence(ith_time,1);
    indexFound = find(sensor_centiTime_to_check==thisTime);
    Nfound = length(indexFound);
    count_of_data_in_reference_time(ith_time,1) = Nfound;

    % Fill up indicies?
    if Nfound>0
        indiciesLocalUsedInReferenceWithOverlaps(ith_time,1) = indexFound(1);
        % Are any data overlapping?
        if Nfound>1
            overlaps{ith_time} = indexFound;
        end
    end
end

% For debugging
if 1==flag_doDebug
    fprintf('\n\n\t\t\tMatching results, before moving overlaps:\n');

    NprintsNearby = min([DEBUG_Nprints length(reference_centisecond_sequence) length(count_of_data_in_reference_time) length(sensor_centiTime_to_check) length(sensor_centiTime_unrounded) length(indiciesLocalUsedInReferenceWithOverlaps)]);
    indicies_to_print = (1:NprintsNearby);
    fullTable = [indicies_to_print' reference_centisecond_sequence(indicies_to_print,:) count_of_data_in_reference_time(indicies_to_print,:) sensor_centiTime_to_check(indicies_to_print,:) sensor_centiTime_unrounded(indicies_to_print,:) indiciesLocalUsedInReferenceWithOverlaps(indicies_to_print,:) ];

    header_strings = [{'Index'}, {'ref_centis'}, {'ref_count'},{'sensor_centis'},{'sensor_unrounded'},{'match'}];
    formatter_strings = [{'%.0d'},{'%.0f'},{'%.0f'},{'%.0f'},{'%.2f'},{'%.0f'}];
    N_chars = 40; % All columns have same number of characters

    table_data = fullTable;
    fcn_DebugTools_debugPrintTableToNCharacters(table_data, header_strings, formatter_strings,N_chars);

end

% Were there any overlaps?
indiciesOverlap = find(count_of_data_in_reference_time>1);
zeroIndicies = find(count_of_data_in_reference_time==0);
if ~isempty(indiciesOverlap)
    % Yes, there were overlaps!
    indiciesLocalUsedInReference = fcn_INTERNAL_removeOverlaps(indiciesLocalUsedInReferenceWithOverlaps, count_of_data_in_reference_time, indiciesOverlap, overlaps, zeroIndicies, sensor_centiTime_unrounded, reference_centisecond_sequence, fid);
else
    indiciesLocalUsedInReference = indiciesLocalUsedInReferenceWithOverlaps;
end

% For debugging
if 1==flag_doDebug
    fprintf('\n\n\t\t\tMatching results, after overlaps removed:\n');
    NprintsNearby = min([DEBUG_Nprints length(reference_centisecond_sequence) length(count_of_data_in_reference_time) length(sensor_centiTime_to_check) length(sensor_centiTime_unrounded) length(indiciesLocalUsedInReference)]);
    indicies_to_print = (1:NprintsNearby);
    fullTable = [indicies_to_print' reference_centisecond_sequence(indicies_to_print,:) count_of_data_in_reference_time(indicies_to_print,:) sensor_centiTime_to_check(indicies_to_print,:) sensor_centiTime_unrounded(indicies_to_print,:) indiciesLocalUsedInReference(indicies_to_print,:) ];

    header_strings = [{'Index'}, {'ref_centis'}, {'ref_count'},{'sensor_centis'},{'sensor_unrounded'},{'match'}];
    formatter_strings = [{'%.0d'},{'%.0f'},{'%.0f'},{'%.0f'},{'%.2f'},{'%.0f'}];
    N_chars = 40; % All columns have same number of characters

    table_data = fullTable;
    fcn_DebugTools_debugPrintTableToNCharacters(table_data, header_strings, formatter_strings,N_chars);
end
end % Ends fcn_INTERNAL_findIndexMapping

%% fcn_INTERNAL_calculateReferenceTimeSequences
function reference_centisecond_sequence = fcn_INTERNAL_calculateReferenceTimeSequences(allsensor_time_duration, sensor_centiSeconds)

% Calculate reference time sequences, one for each sampling rate
% 1 Hz, 5 Hz, 10 Hz, 20 Hz, 25 Hz, 100 Hz
samplingHz = [1; 5; 10; 20; 25; 100];
sampleRatesCentiseconds =  round(100 * 1./samplingHz);
NdifferentSamples = length(sampleRatesCentiseconds);
referenceCentiSecondTimes = cell(NdifferentSamples,1);
for ith_rate = 1:NdifferentSamples
    this_sample_interval = sampleRatesCentiseconds(ith_rate);
    referenceCentiSecondTimes{ith_rate,1} = (0:this_sample_interval:(allsensor_time_duration)*100)';
end


% Determine which reference time sequence we will use. The reference
% time sequence is the one whose centiSeconds value matches the
% centiSeconds on this data
reference_time_index = find(sampleRatesCentiseconds==sensor_centiSeconds);
if isempty(reference_time_index)
    warning('on','backtrace');
    warning('Unable to find matching time index to the sensor centiseconds: %s!', sensor_centiSeconds);
    error('Unable to continue because reference time sampling interval not found.');
end
reference_centisecond_sequence   = referenceCentiSecondTimes{reference_time_index};


end % Ends fcn_INTERNAL_calculateReferenceTimeSequences


%% fcn_INTERNAL_mapSensorIndicies
function replacementData = fcn_INTERNAL_mapSensorIndicies(allSensor_startTime_Seconds, dataToFix, sensor_centiSeconds, sensor_indiciesLocalUsed_InReference, allsensor_time_duration, fill_type, debuggingOffset, fid) %#ok<INUSD>
% Creates a new data set by moving the values from a sensor data set that
% needs to be fixed, using a reference vector that describes which indicies
% in the sensor should be mapped back into the replacement data



flag_doDebug = 0;
debugPrintLength = 30; % How many rows to print for debugging

[~,Ncols] = size(dataToFix);
NreferenceTimes = length(sensor_indiciesLocalUsed_InReference (:,1));
replacementData = nan(NreferenceTimes,Ncols);
indiciesToFill = find(~isnan(sensor_indiciesLocalUsed_InReference));
replacementData(indiciesToFill,:) = dataToFix(sensor_indiciesLocalUsed_InReference(indiciesToFill),:);


% Fix any NaN values
if 0==fill_type
    % Keep the NaN
elseif 1==fill_type

    if 0~=fid
        fprintf(fid,'\t\t Removing NaN values.\n');
    end

    % Make sure the data are strictly increasing
    replacementData_noNan = replacementData(~isnan(replacementData(:,1)),:);
    differences = diff(replacementData_noNan);
    assert(all(differences>0));

    % Determine the reference time sequence to use as a filler
    reference_centisecond_sequence = fcn_INTERNAL_calculateReferenceTimeSequences(allsensor_time_duration, sensor_centiSeconds);

    trueTime     = reference_centisecond_sequence*0.01 + allSensor_startTime_Seconds;

    % For debugging
    if 1==flag_doDebug
        differences  = trueTime - replacementData;
        old_replacementData = replacementData;
        fprintf(1,'\n\n\n\t\t\t Before: \n');
        table_data = [trueTime old_replacementData differences];
        header_strings = [{'trueTime'}, {'sensorTime'},{'differences'}];
        formatter_strings = [{'%.3f'},{'%.3f'},{'%.3f'}];
        N_chars = 15; % All columns have same number of characters
        actualPrintLength = min(debugPrintLength,length(table_data));
        fcn_DebugTools_debugPrintTableToNCharacters(table_data(1:actualPrintLength,:), header_strings, formatter_strings,N_chars);
    end

    % Insert reference times
    badIndicies  = find(isnan(replacementData(:,1)));
    % averageOffset = mean(differences,"omitmissing");

    replacementData(badIndicies,:) = trueTime(badIndicies,:);

    % For debugging
    % new_data = trimmed_dataStructure.(sensor_name).(thisFieldName);
    if 1==flag_doDebug
        fprintf(1,'\n\n\n\t\t\t After: \n');
        differences  = trueTime - replacementData;
        table_data = [trueTime replacementData differences];
        header_strings = [{'trueTime'}, {'sensorTime'},{'differences'}];
        formatter_strings = [{'%.3f'},{'%.3f'},{'%.3f'}];
        N_chars = 15; % All columns have same number of characters
        actualPrintLength = min(debugPrintLength,length(table_data));
        fcn_DebugTools_debugPrintTableToNCharacters(table_data(1:actualPrintLength,:), header_strings, formatter_strings,N_chars);
    end

    % Make sure the data is sorted
    differences = diff(replacementData);
    assert(~any(differences<0));

end

end % fcn_INTERNAL_mapSensorIndicies

%% fcn_INTERNAL_mapAllFieldsInSensor
function trimmed_dataStructure = fcn_INTERNAL_mapAllFieldsInSensor(allSensor_startTime_Seconds, lengthReference, dataStructure, sensor_name, sensor_centiSeconds, sensor_data, sensor_indiciesLocalUsed_InReference, field_name, allsensor_time_duration, debuggingOffset, fid)
% Goes through all the sensors, filling bad data with NaN values. Skips the
% field associated with the query field (ROS_Time for example) and skips
% also GPS_Time.

trimmed_dataStructure = dataStructure;

% Loop through all subfields
subfieldNames = fieldnames(sensor_data);
for i_subField = 1:length(subfieldNames)
    % Grab the name of the ith subfield
    thisFieldName = subfieldNames{i_subField};
    if ~strcmp(thisFieldName,field_name) && ~strcmp(thisFieldName,'GPS_Time')

        dataToFix = dataStructure.(sensor_name).(thisFieldName);
        [Nrows,~] = size(dataToFix);

        if ~iscell(dataToFix) % Is it a cell? If yes, skip it
            if Nrows ~= 1 % Is it a scalar? If yes, skip it
                % It's an array, make sure it has right length
                if lengthReference~= length(dataToFix)
                    if strcmp(sensor_name,'SickLiDAR') && strcmp(thisFieldName,'Sick_Time')
                        warning('on','backtrace');
                        warning('SICK lidar has a time vector that does not match data arrays. This will make this data unusable.');
                    elseif strcmp(sensor_name,'TRIGGER_TrigBox_RearTop') && strcmp(thisFieldName,'Mode')
                        warning('on','backtrace');
                        warning('Trigger box ''Mode'' skipped - it will not match other data.');
                    elseif strcmp(sensor_name,'ENCODER_USDigital_RearAxle') && strcmp(thisFieldName,'Mode')
                        warning('on','backtrace');
                        warning('Encoder box ''Mode'' skipped - it will not match other data.');
                    else
                        warning('on','backtrace');
                        warning('Sensor %s contains a datafield %s that has an amount of data not equal to the %s. This is usually because data is missing.',sensor_name,thisFieldName, field_name);
                    end
                else
                    % Replace the values
                    data_fill_type = 0; % For data, never want to fill in the missing data with any values
                    replacementData = fcn_INTERNAL_mapSensorIndicies(allSensor_startTime_Seconds, dataToFix, sensor_centiSeconds, sensor_indiciesLocalUsed_InReference, allsensor_time_duration, data_fill_type, debuggingOffset, fid);
                    trimmed_dataStructure.(sensor_name).(thisFieldName) = replacementData;
                end
            end
        end
    end
end
end % fcn_INTERNAL_mapAllFieldsInSensor
