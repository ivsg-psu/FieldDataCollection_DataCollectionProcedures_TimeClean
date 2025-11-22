%% fcn_TimeClean_checkROSTimeRoundsCorrectly
function fixed_dataStructure = fcn_TimeClean_roundROSTimeForGPSUnits(dataStructure, varargin)
% fcn_TimeClean_roundROSTimeForGPSUnits(dataStructure,fid)
% fcn_TimeClean_roundROSTimeForGPSUnits
% Given a data structure, round ROS time of GPS units to the centiSecond
% value
%
% FORMAT:
%
%      fixed_dataStructure = fcn_TimeClean_roundROSTimeForGPSUnits(dataStructure, (sensot_type), (fid))
%
% INPUTS:
%
%      dataStructure: a data structure to be analyzed
%
%      (OPTIONAL INPUTS)
%
%
%      fid: a file ID to print results of analysis. If not entered, no
%      output is given (FID = 0). Set fid to 1 for printing to console.
%
% OUTPUTS:
%
%      fixed_dataStructure: a data structure to be analyzed that includes the following
%      fields:
%
% 
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%
% EXAMPLES: # to be done
%
%     See the script: script_test_fcn_TimeClean_roundROSTimeForGPSUnits
%     for a full test suite.
%
% This function was written on 2024_08_09 by X. Cao
% Questions or comments? xfc5113@psu.edu 

% Revision history:
%     
% 2024_08_09: xfc5113@psu.edu
% -- wrote the code originally 
% 2024_10_07: xfc5113@psu.edu
% -- fix bugs in Trigger_Time calculation



flag_do_debug = 1;  % Flag to show the results for debugging
flag_do_plots = 0;  % Flag to plot the final results
flag_check_inputs = 1; % Flag to perform input checking


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

if flag_check_inputs
    % Are there the right number of inputs?
    if nargin < 1 || nargin > 2
        error('Incorrect number of input arguments')
    end
        
end

% Does the user want to specify the sensor_type?
sensor_type = 'gps';

% Does the user want to specify the fid?
% Check for user input
fid = 0; % Default case is to NOT print to the console

if 2 == nargin
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

if fid
    st = dbstack; %#ok<*UNRCH>
    fprintf(fid,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
end

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

% The method this is done is to:
% 1. Find the effective start and end ROS_Times, determined by taking the maximum start time and minimum end time over all
% sensors.
% 2.  Recalculates the common ROS_Time field for all sensors. This is done by
% using the centiSeconds field.

%% Step 1: Find the effective start and end times over all sensors
%% Find centiSeconds
[cell_array_centiSeconds,sensor_names_centiSeconds] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'centiSeconds',sensor_type,'first_row');

% Convert centiSeconds to a column matrix
array_centiSeconds = cell2mat(cell_array_centiSeconds)';

% To synchronize sensors, take maximum sampling rate so all sensors have
% data from the start
max_sampling_period_centiSeconds = max(array_centiSeconds);

if 0~=fid
    fprintf(fid,'\nCalculating Trigger_Time by checking start and end times across GPS sensors:\n');
end



%% Find start time
[cell_array_ROS_Time_start,sensor_names_ROS_Time]         = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'ROS_Time',sensor_type,'first_row');

% Confirm that both results are identical
if ~isequal(sensor_names_ROS_Time,sensor_names_centiSeconds)
    error('Sensors were found that were missing either GPS_Time or centiSeconds. Unable to calculate Trigger_Times.');
end

% Convert GPS_Time_start to a column matrix
array_ROS_Time_start = cell2mat(cell_array_ROS_Time_start)';

% Find when each sensor's start time lands on this centiSecond value, rounding up
all_start_times_centiSeconds = ceil(100*array_ROS_Time_start/max_sampling_period_centiSeconds)*max_sampling_period_centiSeconds;

% Warn if max/min are WAY off (like more than 1 second)
if (max(all_start_times_centiSeconds)-min(all_start_times_centiSeconds))>100
    error('The start times on different GPS sensors appear to be untrimmed to same value. The Trigger_Time calculations will give incorrect results if the data are not trimmed first.');
end
centitime_all_sensors_have_started_ROS_Time = max(all_start_times_centiSeconds);

% Show the results?
if fid
    longest_name_string = 0;
    for ith_name = 1:length(sensor_names_ROS_Time)
        if length(sensor_names_ROS_Time{ith_name})>longest_name_string
            longest_name_string = length(sensor_names_ROS_Time{ith_name});
        end
    end
    fprintf(fid,'\t \t Summarizing start times: \n');
    sensor_title_string = fcn_DebugTools_debugPrintStringToNCharacters('Sensors:',longest_name_string);
    posix_title_string = fcn_DebugTools_debugPrintStringToNCharacters('Posix Time (sec since 1970):',29);
    datetime_title_string = fcn_DebugTools_debugPrintStringToNCharacters('Date Time:',25);
    fprintf(fid,'\t \t %s \t %s \t %s \n',sensor_title_string,posix_title_string,datetime_title_string);
    for ith_data = 1:length(sensor_names_ROS_Time)
        sensor_data_string = fcn_DebugTools_debugPrintStringToNCharacters(sensor_names_ROS_Time{ith_data},longest_name_string);
        posix_data_string = fcn_DebugTools_debugPrintStringToNCharacters(sprintf('%.6f',array_ROS_Time_start(ith_data)),29);
        time_in_datetime = datetime(array_ROS_Time_start(ith_data),'convertfrom','posixtime','format','yyyy-MM-dd HH:mm:ss.SSS');
        
        time_string = sprintf('%s',time_in_datetime);
        datetime_data_string = fcn_DebugTools_debugPrintStringToNCharacters(time_string,25);
        fprintf(fid,'\t \t %s \t %s \t %s \n',sensor_data_string,posix_data_string,datetime_data_string);
    end
    fprintf(fid,'\n');
end

%% Find end time
[cell_array_ROS_Time_end,sensor_names_ROS_Time]         = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'ROS_Time',sensor_type,'last_row');

% Confirm that both results are identical
if ~isequal(sensor_names_ROS_Time,sensor_names_centiSeconds)
    error('Sensors were found that were missing either ROS_Time or centiSeconds. Unable to calculate Trigger_Times.');
end

% Convert GPS_Time_start to a column matrix
array_ROS_Time_end = cell2mat(cell_array_ROS_Time_end)';

% Find when each sensor's end time lands on this centiSecond value,
% rounding down
all_end_times_centiSeconds = floor(100*array_ROS_Time_end/max_sampling_period_centiSeconds)*max_sampling_period_centiSeconds;

% Warn if max/min are WAY off (like more than 1 second)
if (max(all_end_times_centiSeconds)-min(all_end_times_centiSeconds))>100
    error('The end times on different GPS sensors appear to be untrimmed to same value. The Trigger_Time calculations will give incorrect results if the data are not trimmed first.');
end
centitime_all_sensors_have_ended_ROS_Time = min(all_end_times_centiSeconds);

% Show the results?
if fid
    fprintf(fid,'\t \t Summarizing end times: \n');    
    sensor_title_string = fcn_DebugTools_debugPrintStringToNCharacters('Sensors:',longest_name_string);
    posix_title_string = fcn_DebugTools_debugPrintStringToNCharacters('Posix Time (sec since 1970):',29);
    datetime_title_string = fcn_DebugTools_debugPrintStringToNCharacters('Date Time:',25);
    fprintf(fid,'\t \t %s \t %s \t %s \n',sensor_title_string,posix_title_string,datetime_title_string);
    for ith_data = 1:length(sensor_names_ROS_Time)
        sensor_data_string = fcn_DebugTools_debugPrintStringToNCharacters(sensor_names_ROS_Time{ith_data},longest_name_string);
        posix_data_string = fcn_DebugTools_debugPrintStringToNCharacters(sprintf('%.6f',array_ROS_Time_end(ith_data)),29);
        time_in_datetime = datetime(array_ROS_Time_end(ith_data),'convertfrom','posixtime','format','yyyy-MM-dd HH:mm:ss.SSS');
        
        time_string = sprintf('%s',time_in_datetime);
        datetime_data_string = fcn_DebugTools_debugPrintStringToNCharacters(time_string,25);
        fprintf(fid,'\t \t %s \t %s \t %s \n',sensor_data_string,posix_data_string,datetime_data_string);
    end
    fprintf(fid,'\n');
end
if fid
    fprintf(fid,'\t The Trigger_Time is using the following GPS_Time range: \n');
    fprintf(fid,'\t\t Start Time (UTC seconds): %.3f\n',centitime_all_sensors_have_started_ROS_Time/100);
    fprintf(fid,'\t\t End Time   (UTC seconds): %.3f\n',centitime_all_sensors_have_ended_ROS_Time/100);
    fprintf(fid,'\n');
end

%% Step 2: Round ROS_Time to centiSeconds

[cell_array_ROS_Time,sensor_names_ROS_Time]         = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'ROS_Time',sensor_type);

% Initialize the result:
fixed_dataStructure = dataStructure;

% Loop through the fields, searching for ones that have "GPS" in their name
for ith_sensor = 1:length(sensor_names_ROS_Time)
    % Grab the sensor subfield name
    sensor_name = sensor_names_ROS_Time{ith_sensor};
    
    if 0~=fid
        fprintf(fid,'\t Filling Trigger_Time in sensor %d of %d to have correct start and end GPS_Time values: %s\n',ith_sensor,length(sensor_names_ROS_Time),sensor_name);
    end
    % Grab centiSeconds
    centiSeconds = cell_array_centiSeconds{ith_sensor};
    % Grab Trigger_Time  
    [cell_array_Trigger_Time,sensor_names_Trigger_Time]  = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'Trigger_Time',sensor_type);
    %
    if ~isequal(sensor_names_Trigger_Time,sensor_names_ROS_Time)
        error("GPS sensors do not match, ROS_Time cannot be rounded to Trigger Time")
        
    end

    % Calculate round ROS_Time
    ROS_Time_original = cell_array_ROS_Time{ith_sensor};
    Trigger_Time_original = cell_array_Trigger_Time{ith_sensor};
    offsets_between_TriggerTime_and_ROSTime = ROS_Time_original - Trigger_Time_original;
    rounded_centiSecond_ROS_Time = round(100*ROS_Time_original/centiSeconds)*centiSeconds;
    rounded_centiSecond_Trigger_Time = round(100*Trigger_Time_original/centiSeconds)*centiSeconds;
    N_points = length(ROS_Time_original);

    % Check if the rounded ROS_Time_strictly_ascends
    rounded_centiSecond_ROS_Time_diff = diff(rounded_centiSecond_ROS_Time);
    if rounded_centiSecond_ROS_Time_diff(1) == 0
        rounded_centiSecond_ROS_Time_start = rounded_centiSecond_ROS_Time(1) - centiSeconds/100;
    else
        rounded_centiSecond_ROS_Time_start = rounded_centiSecond_ROS_Time(1);
    end
    rounded_centiSecond_ROS_Time_end = rounded_centiSecond_ROS_Time_start+(N_points-1)*centiSeconds;
    % ROS_Time_strictly_ascends = all(rounded_centiSecond_ROS_Time_diff>0);
    % rounded_centiSecond_ROS_Time_fixed = rounded_centiSecond_ROS_Time;
    % if ROS_Time_strictly_ascends == 0
    %     flat_indices = find(rounded_centiSecond_ROS_Time_diff == 0);
    %     turning_indices = find(rounded_centiSecond_ROS_Time_diff > centiSeconds);
    %     indices_need_to_be_refilled = [flat_indices;turning_indices];
    %     for time_index = 1:length(flat_indices)
    %         flat_index = flat_indices(time_index);
    %         [~,closest_index] = min(abs(turning_indices - flat_index));
    %         turning_index = turning_indices(closest_index);
    %         if turning_index>flat_index
    %             wrong_indices = (flat_index:1:turning_index).';
    %         else
    %             wrong_indices = (turning_index:1:flat_index).';
    %         end
    %         indices_need_to_be_refilled = [indices_need_to_be_refilled; wrong_indices];
    %     end
    % 
    %     unique_indices = unique(indices_need_to_be_refilled,'sorted');
    %     rounded_centiSecond_ROS_Time_fixed(unique_indices) = nan;
    %     rounded_centiSecond_ROS_Time_fixed = fillmissing(rounded_centiSecond_ROS_Time_fixed,'linear');
    % end 
    rounded_centiSecond_ROS_Time_fixed = (rounded_centiSecond_ROS_Time_start:centiSeconds:rounded_centiSecond_ROS_Time_end).';
    fixed_dataStructure.(sensor_name).ROS_Time = rounded_centiSecond_ROS_Time_fixed/100;

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

