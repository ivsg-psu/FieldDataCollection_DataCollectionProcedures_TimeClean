function [cleanDataStruct, subPathStrings]  = fcn_TimeClean_cleanTime(rawDataStruct, varargin)


warning('on','backtrace');
warning(['fcn_TimeClean_cleanTime is being deprecated. ' ...
    'Use fcn_TimeClean_cleanTimeInStruct instead.']);



% fcn_TimeClean_cleanTimeInStruct
% given a raw data structure, cleans time jumps, time out-of-ordering, and
% time alignment between ROS and GPS time
%
% FORMAT:
%
%      cleanDataStruct = fcn_TimeClean_cleanTime(rawDataStruct, (fid), (Flags), (saveFlags), (plotFlags))
%
% INPUTS:
%
%      rawDataStruct: a  data structure containing data fields filled for
%      each ROS topic. If multiple bag files are specified, a cell array of
%      data structures is returned.
%
%      (OPTIONAL INPUTS)
%
%      fid: the fileID where to print. Default is 1, to print results to
%      the console.
%
%      Flags: a structure containing key flags to set the process. The
%      defaults, and explanation of each, are below:
%
%           Flags.flag_do_load_sick = 0; % Loads the SICK LIDAR data
%           Flags.flag_do_load_velodyne = 0; % Loads the Velodyne LIDAR
%           Flags.flag_do_load_cameras = 0; % Loads camera images
%           Flags.flag_select_scan_duration = 0; % Lets user specify scans from Velodyne
%           Flags.flag_do_load_GST = 0; % Loads the GST field from Sparkfun GPS Units          
%           Flags.flag_do_load_VTG = 0; % Loads the VTG field from Sparkfun GPS Units
%
%      saveFlags: a structure of flags to determine how/where/if the
%      results are saved. The defaults are below
%
%         saveFlags.flag_saveMatFile = 0; % Set to 1 to save each rawData
%         file into the directory
%
%         saveFlags.flag_saveMatFile_directory = ''; % String with full
%         path to the directory where to save mat files
%
%         saveFlags.flag_saveImages = 0; % Set to 1 to save each image
%         file into the directory
%
%         saveFlags.flag_saveImages_directory = ''; % String with full
%         path to the directory where to save image files
%
%      plotFlags: a structure of figure numbers to plot results. If set to
%      -1, skips any input checking or debugging, no figures will be
%      generated, and sets up code to maximize speed. The structure has the
%      following format:
%
%            plotFlags.figNum_checkTimeSamplingConsistency_GPSTime
%            plotFlags.figNum_checkTimeSamplingConsistency_ROSTime
%            plotFlags.figNum_fitROSTime2GPSTime
%
%
% OUTPUTS:
%
%      cleanDataStruct: a  data structure containing data fields filled for
%      each ROS topic, in cleaned form.
%
%     subPathStrings: a string for each rawData load indicating the subpath
%     where the data was obtained
%
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%      fcn_TimeClean_mergeSensorsByMethod
%
% EXAMPLES:
%
%     See the script: script_test_fcn_TimeClean_cleanTime
%     for a full test suite.
%
% This function was written on 2024_09_09 by S. Brennan
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY
% 
% 2024_09_09 by S. Brennan
% - Wrote the code originally pulling it out of the main script
% 
% 2024_09_23 by X. Cao
% - add fcn_TimeClean_trimDataToCommonStartEndTriggerTimes to the while
% loop
% 
% 2024_09_23 by Sean Brennan, sbrennan@psu.edu
% - Removed environment variable setting within function (not good
% practice)
% 
% 2024_09_27 - X. Cao
% - move fcn_TimeClean_checkAllSensorsHaveTriggerTime into fcn_TimeClean_checkDataTimeConsistency
% - add a step to temporary remove Identifiers from rawDataStruct before
% the while loop and fill it back later
% 
% 2024_11_05 by Sean Brennan, sbrennan@psu.edu
% - Removed name cleaning code and moved to a different function
% - separated cleanTime out from cleanData
% - Removed refLLA input
% - Added saveFlags and plotFlags
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - Changed in-use function name
%   % * From: fcn_LoadRawDataTo+MATLAB_pullDataFromFieldAcrossAllSensors
%   % * To: fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll
%
% As:
%
% 2025_11_25 by Sean Brennan, sbrennan@psu.edu
% - Renamed function to better distinguish that it is operating only on a
%   % structure input, not as a full directory-level clean
%   % From: fcn_TimeClean_cleanTime
%   % To: fcn_TimeClean_cleanTimeInStruct

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)


%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the figNum variable input
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
    MATLABFLAG_TIMECLEAN_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_TIMECLEAN_FLAG_CHECK_INPUTS");
    MATLABFLAG_TIMECLEAN_FLAG_DO_DEBUG = getenv("MATLABFLAG_TIMECLEAN_FLAG_DO_DEBUG");
    if ~isempty(MATLABFLAG_TIMECLEAN_FLAG_CHECK_INPUTS) && ~isempty(MATLABFLAG_TIMECLEAN_FLAG_DO_DEBUG)
        flag_do_debug = str2double(MATLABFLAG_TIMECLEAN_FLAG_DO_DEBUG);
        flag_check_inputs  = str2double(MATLABFLAG_TIMECLEAN_FLAG_CHECK_INPUTS);
    end
end

% flag_do_debug = 1;

if flag_do_debug
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
    debug_figNum = 999978; %#ok<NASGU>
else
    debug_figNum = []; %#ok<NASGU>
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

if 0 == flag_max_speed
    if flag_check_inputs == 1
        % Are there the right number of inputs?
        narginchk(1,5);

    end
end

% Does user want to specify fid?
fid = 1;
if 2 <= nargin
    temp = varargin{1};
    if ~isempty(temp)
        fid = temp;
    end
end


% Does user specify Flags?
% Set defaults
Flags.flag_do_load_SICK = 0;
Flags.flag_do_load_Velodyne = 0;
Flags.flag_do_load_cameras = 0;
Flags.flag_select_scan_duration = 0;
Flags.flag_do_load_GST = 0;
Flags.flag_do_load_VTG = 0; %#ok<STRNU>
if 3 <= nargin
    temp = varargin{2};
    if ~isempty(temp)
        Flags = temp; %#ok<NASGU>
        
    end
end



% Does user specify saveFlags?
% Set defaults
saveFlags.flag_saveMatFile = 0;
saveFlags.flag_saveMatFile_directory = '';
saveFlags.flag_saveImages = 0;
saveFlags.flag_saveImages_directory = '';
if 4 <= nargin
    temp = varargin{3};
    if ~isempty(temp)
        saveFlags = temp;
    end
end

% Does user want to specify plotFlags?
% Set defaults
plotFlags.figNum_checkTimeSamplingConsistency_GPSTime = [];
plotFlags.figNum_checkTimeSamplingConsistency_ROSTime = [];
plotFlags.figNum_fitROSTime2GPSTime                   = [];
flag_do_plots = 0;
if (0==flag_max_speed) &&  (5<=nargin)
    temp = varargin{end};
    if ~isempty(temp)
        plotFlags = temp;
        flag_do_plots = 1;
    end
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


%% Define the stitching points based on the site's start and end locations
% This section takes a user-given start and end location for a site, and
% identifies which data sets 

%% Fill in test cases?
% Fill in the initial data - we use this for testing
% dataStructure = fcn_LoadRawDataToMATLAB_fillTestDataStructure;

%% Start the looping process to iteratively clean data
% The method used below is as follows:
% - The data is initialized before the loop by loading (see above)
% - The loop is started, and for each version of the loop, the data is
%    checked to see if there are any errors measured in the data.
% - For each error type, a flag is set that is used to initiate a process
%    that seeks to remove that type of error.
% 
% For example: say the data has wrap-around error on yaw angle due to angle
% roll-over. This is checked and reported, and a function is called if this
% is detected to fix that error.

flag_stay_in_main_loop = 1;
N_max_loops = 5;

% Preallocate the data array
debugging_data_structure_sequence{N_max_loops} = struct;

main_data_clean_loop_iteration_number = 0; % The first iteration corresponds to the raw data loading
currentDataStructure = rawDataStruct;
% Grab the Indentifiers field from the rawDataStructure
Identifiers_Hold = rawDataStruct.Identifiers;


%%
while 1==flag_stay_in_main_loop   
    %% Keep data thus far
    main_data_clean_loop_iteration_number = main_data_clean_loop_iteration_number+1;
    debugging_data_structure_sequence{main_data_clean_loop_iteration_number} = currentDataStructure;

    fprintf(1,'\n\n ----------------------------------------------------------------------------------------------------------------\n');
    fprintf(1,'\n\nTime Cleaning Iteration #%.0d\n',main_data_clean_loop_iteration_number);

    %% Remove Identifiers, temporarily
    if isfield(currentDataStructure, 'Identifiers')
        nextDataStructure = rmfield(currentDataStructure,'Identifiers');
    else
        nextDataStructure = currentDataStructure;
    end
    
    
    %% Data cleaning processes to fix the latest error start here
    flag_keep_checking = 1; % Flag to keep checking (1), or to indicate a data correction is done and checking should stop (0)
    
  
    %% GPS_Time tests - all of these steps can be found in fcn_TimeClean_checkDataTimeConsistency, the following sections need to be deleted later
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %    _____ _____   _____            _______ _                   _______        _
    %   / ____|  __ \ / ____|          |__   __(_)                 |__   __|      | |
    %  | |  __| |__) | (___               | |   _ _ __ ___   ___      | | ___  ___| |_ ___
    %  | | |_ |  ___/ \___ \              | |  | | '_ ` _ \ / _ \     | |/ _ \/ __| __/ __|
    %  | |__| | |     ____) |             | |  | | | | | | |  __/     | |  __/\__ \ |_\__ \
    %   \_____|_|    |_____/              |_|  |_|_| |_| |_|\___|     |_|\___||___/\__|___/
    %                          ______
    %                         |______|
    %
    % See: http://patorjk.com/software/taag/#p=display&f=Big&t=GPS%20_%20Time%20%20Tests
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
    
    %% Check data for errors in Time data related to GPS-enabled sensors -- Done
    % Fills in the following
    % GPS_Time_exists_in_at_least_one_GPS_sensor        	yes
    % GPS_Time_exists_in_all_GPS_sensors                	yes
    % centiSeconds_exists_in_all_GPS_sensors            	yes
    % GPS_Time_has_no_repeats_in_GPS_sensors            	yes
    % GPS_Time_strictly_ascends_in_GPS_sensors          	yes
    % GPS_Time_sample_modes_match_centiSeconds_in_GPS_se	yes
    % GPS_Time_has_consistent_start_end_within_5_seconds	yes
    % GPS_Time_has_consistent_start_end_across_GPS_senso	yes
    % GPS_Time_has_no_sampling_jumps_in_any_GPS_sensors 	yes
    % GPS_Time_has_no_missing_sample_differences_in_any_	yes
    % Trigger_Time_exists_in_all_GPS_sensors            	yes
    % ROS_Time_exists_in_all_GPS_sensors                	yes
    % ROS_Time_scaled_correctly_as_seconds              	yes
    % ROS_Time_strictly_ascends_in_GPS_sensors          	yes
    % ROS_Time_sample_modes_match_centiSeconds_in_GPS_se	yes
    % ROS_Time_has_same_length_as_Trigger_Time_in_GPS_se	yes
    % ROS_Time_rounds_correctly_to_Trigger_Time_in_GPS_s	yes
    % Trigger_Time_exists_in_all_sensors                	yes

    % Used to create test data
    if 1==0
        fullExampleFilePath = fullfile(cd,'Data','ExampleData_checkDataTimeConsistency.mat');
        dataStructure = nextDataStructure;
        save(fullExampleFilePath,'dataStructure');
    end

    if (1==flag_keep_checking)
        [time_flags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(nextDataStructure, fid, plotFlags);
    end
    
    fcn_INTERNAL_reportFlagStatus(time_flags,'TIMING FLAGS');

    %% Check if GPS_Time_exists_in_at_least_one_GPS_sensor
    %    ### ISSUES with this:
    %    * There is no absolute time base to use for the data
    %    * The tracking of vehicle data relative to external sourses is no
    %    longer possible
    %    ### DETECTION:
    %    * Examine if GPS time fields exist on any GPS sensor
    %    ### FIXES:
    %    * Catastrophic error. Data collection should end.
    %    * One option? Check if ROS_Time recorded, and is locked to UTC via NTP, use ROS
    %    Time as stand-in
    %    * Otherwise, complete failure of sensor recordings
    
    if (1==flag_keep_checking) && (0==time_flags.GPS_Time_exists_in_at_least_one_GPS_sensor)
        warning('on','backtrace');
        warning('Fundamental error on GPS_time: no sensors detected that have GPS time!?');
        error('Catastrophic data error detected: no GPS_Time data detected in any sensor.');
    end
    
    
    %% Check if GPS_Time_exists_in_all_GPS_sensors
    %    ### ISSUES with this:
    %    * There is no absolute time base to use for the sensor
    %    * This usually indicates back lock for the GPS
    %    ### DETECTION:
    %    * Examine if GPS time fields exist on all GPS sensors
    %    ### FIXES:
    %    * If another GPS is available, use its time alongside the GPS data
    %    * Remove this GPS data field
    
    if (1==flag_keep_checking) && (0==time_flags.GPS_Time_exists_in_all_GPS_sensors)
        warning('on','backtrace');
        warning('Fundamental error on GPS_time: a GPS sensor is missing GPS time!?');
        error('Catastrophic data error detected: the following GPS sensor is missing GPS_Time data: %s.',offending_sensor);        
    end
    
    %% Check if centiSeconds_exists_in_all_GPS_sensors
    %    ### ISSUES with this:
    %    * This field defines the expected sample rate for each sensor
    %    ### DETECTION:
    %    * Examine if centiSeconds fields exist on all sensors
    %    ### FIXES:
    %    * Manually fix, or
    %    * Remove this sensor
    
    if (1==flag_keep_checking) && (0==time_flags.centiSeconds_exists_in_all_GPS_sensors)
        disp(nextDataStructure.(offending_sensor))
        warning('on','backtrace');
        warning('Fundamental error on GPS_time: a GPS sensor is missing centiSeconds!?');
        error('Catastrophic data error detected: the following GPS sensor is missing centiSeconds: %s.',offending_sensor);                
    end
    


    %% Check if GPS_Time_has_no_repeats_in_GPS_sensors
    %    ### ISSUES with this:
    %    * If there are many repeated time values, the calculation of sampling
    %    time in the future steps produces incorrect results
    %    ### DETECTION:
    %    * Examine if time values are unique
    %    ### FIXES:
    %    * Remove repeats

    if (1==flag_keep_checking) && (0==time_flags.GPS_Time_has_no_repeats_in_GPS_sensors)
        % Fix the data
        field_name = 'GPS_Time';
        sensors_to_check = 'GPS';
        nextDataStructure = fcn_TimeClean_trimRepeatsFromField(nextDataStructure,fid, field_name,sensors_to_check);
        flag_keep_checking = 0;
    end



    %% Check if GPS_Time_sample_modes_match_centiSeconds_in_GPS_sensors
    %    ### ISSUES with this:
    %    * This field is used to confirm GPS sampling rates for all
    %    GPS-triggered sensors
    %    * These sensors are used to correct ROS timings, so if misisng, the
    %    timing and thus positioning of vehicle data may be wrong
    %    * The GPS unit may be configured wrong
    %    * The GPS unit may be faililng or operating incorrectly
    %    ### DETECTION:
    %    * Make sure centiSeconds exists in all GPS sensors
    %    * Examine if centiSeconds calculation of time interval matches GPS
    %    time interval for data collection, on average
    %    ### FIXES:
    %    * Manually fix, or
    %    * Remove this sensor
    
    if (1==flag_keep_checking) && (0==time_flags.GPS_Time_sample_modes_match_centiSeconds_in_GPS_sensors)
        warning('on','backtrace');
        warning('A GPS sensor has a sampling rate different than expected by centiSeconds!?');
        error('Inconsistent data detected: the following GPS sensor has an average sampling rate different than predicted from centiSeconds: %s.',offending_sensor);                
    end
    
    
    %% Check if GPS_Time_has_consistent_start_end_within_5_seconds
    %    ### ISSUES with this:
    %    * The start times of all sensors in general should be the same,
    %    within a few seconds, as this is the boot-up time for sensors
    %    * If the times are severely wrong, this can indicate that the
    %    sensors are giving bad data
    %    * As an example, on 2023_06_22, a new GPS antenna installed on the
    %    mapping van produced time that was not UTC, but EST, resulting in
    %    a 4-hour difference in start times
    %    ### DETECTION:
    %    * Seach through the GPS time fields for all sensors, rounding them to
    %    their appropriate centi-second values
    %    * Check that they all agree within 5 seconds
    %    ### FIXES:
    %    * Use GPS sensors to "vote" on actual start time. For outliers,
    %    try different time shifts to minimize error. If error is reduced
    %    to less than 5 seconds, then the fix worked. Otherwise, throw an
    %    error.
    
    if (1==flag_keep_checking) && (0==time_flags.GPS_Time_has_consistent_start_end_within_5_seconds)
        nextDataStructure = fcn_TimeClean_correctTimeZoneErrorsInGPSTime(nextDataStructure,fid);
        flag_keep_checking = 0;
    end
    
    %% Check if GPS_Time_has_consistent_start_end_across_GPS_sensors
    %    ### ISSUES with this:
    %    * The start times and end times of all data collection assumes all GPS
    %    systems are operating simultaneously
    %    * The calculation of Trigger_Time assumes that all start times are the
    %    same, and all end times are the same
    %    * If they are not the same, the count of data in one sensor may be
    %    different than another, especially if each were referencing different
    %    GPS sources.
    %    ### DETECTION:
    %    * Seach through the GPS time fields for all sensors, rounding them to
    %    their appropriate centi-second values
    %    * Check that they all agree
    %    ### FIXES:
    %    * Crop all data to same starting centi-second value

    if (1==flag_keep_checking) && (0==time_flags.GPS_Time_has_consistent_start_end_across_GPS_sensors)
        % Used to create test data
        if 1==0
            fullExampleFilePath = fullfile(cd,'Data','ExampleData_trimDataToCommonStartEndGPSTimes.mat');
            dataStructure = nextDataStructure;
            save(fullExampleFilePath,'dataStructure');
        end

        field_name = 'GPS_Time';
        sensors_to_check = 'GPS';
        fill_type = 1;
        nextDataStructure = fcn_TimeClean_trimDataToCommonStartEndGPSTimes(nextDataStructure, (field_name), (sensors_to_check), (fill_type), (fid));
        flag_keep_checking = 0;
    end

    %% Check if GPS_Time_strictly_ascends_in_GPS_sensors
    %    ### ISSUES with this:
    %    * This field is used to calibrate ROS time via interpolation, and must
    %    be STRICTLY increasing
    %    * If data packets arrive out-of-order with this sensor, times may not
    %    be in an increasing sequence
    %    * If a GPS is glitching, its time may be temporarily incorrect
    %    ### DETECTION:
    %    * Examine if time data from sensor is STRICTLY increasing
    %    ### FIXES:
    %    * Remove and interpolate time field if not strictkly increasing
    %    * Re-order data, if minor ordering error
    
    if (1==flag_keep_checking) && (0==time_flags.GPS_Time_strictly_ascends_in_GPS_sensors)
        field_name = 'GPS_Time';
        sensors_to_check = 'GPS';
        fid = 1;
        nextDataStructure = fcn_TimeClean_sortSensorDataByGPSTime(nextDataStructure, field_name,sensors_to_check,fid);               
        flag_keep_checking = 0;
    end


    %% Check if GPS_Time_has_no_sampling_jumps_in_any_GPS_sensors
    %    ### ISSUES with this:
    %    * The GPS_Time may have small jumps which could occur if the sensor
    %    pauses for a moment, then restarts
    %    * If these jumps are large, the data from the sensor may be corrupted
    %    ### DETECTION:
    %    * Examine if the differences in GPS_Time are out of ordinary by
    %    looking at the standard deviations of the differences relative to the
    %    mean differences
    %    ### FIXES:
    %    * Interpolate time field if only a small segment is missing     

    if (1==flag_keep_checking) && (0==time_flags.GPS_Time_has_no_sampling_jumps_in_any_GPS_sensors)
        % Used to create test data
        if 1==0
            fullExampleFilePath = fullfile(cd,'Data','ExampleData_fillMissingsInGPSUnits.mat');
            dataStructure = nextDataStructure;
            save(fullExampleFilePath,'dataStructure');
        end
        nextDataStructure = fcn_TimeClean_fillMissingsInGPSUnits(nextDataStructure, fid);
        flag_keep_checking = 0;
    end
    
    % %% Check if GPS_Time_has_no_missing_sample_differences_in_any_GPS_sensors
    % %    ### ISSUES with this:
    % %    * The GPS_Time may have small jumps which could occur if the sensor
    % %    pauses for a moment, then restarts
    % %    * If these jumps are large, the data from the sensor may be corrupted
    % %    ### DETECTION:
    % %    * Examine if the differences in GPS_Time are out of ordinary by
    % %    looking at the standard deviations of the differences relative to the
    % %    mean differences
    % %    ### FIXES:
    % %    * Interpolate time field if only a small segment is missing        
    % 
    if (1==flag_keep_checking) && (0==time_flags.GPS_Time_has_no_missing_sample_differences_in_any_GPS_sensors)
        nextDataStructure = fcn_TimeClean_fillMissingsInGPSUnits(nextDataStructure, fid);
        flag_keep_checking = 0;    
    end

     %% Trigger_Time Tests
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   _______   _                                  _______ _                   _______        _
    %  |__   __| (_)                                |__   __(_)                 |__   __|      | |
    %     | |_ __ _  __ _  __ _  ___ _ __              | |   _ _ __ ___   ___      | | ___  ___| |_ ___
    %     | | '__| |/ _` |/ _` |/ _ \ '__|             | |  | | '_ ` _ \ / _ \     | |/ _ \/ __| __/ __|
    %     | | |  | | (_| | (_| |  __/ |                | |  | | | | | | |  __/     | |  __/\__ \ |_\__ \
    %     |_|_|  |_|\__, |\__, |\___|_|                |_|  |_|_| |_| |_|\___|     |_|\___||___/\__|___/
    %                __/ | __/ |            ______
    %               |___/ |___/            |______|
    %
    % See: http://patorjk.com/software/taag/#p=display&f=Big&t=Trigger%20_%20Time%20%20Tests
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% Check if Trigger_Time_exists_in_all_GPS_sensors
    %    ### ISSUES with this:
    %    * This field is used to assign data collection timings for all
    %    non-GPS-triggered sensors, and to fill in GPS_Time data if there's a
    %    short outage
    %    * These sensors may be configured wrong
    %    * These sensors may be faililng or operating incorrectly
    %    ### DETECTION:
    %    * Examine if Trigger_Time fields exist
    %    ### FIXES:
    %    * Recalculate Trigger_Time fields as needed, using centiSeconds

    if (1==flag_keep_checking) && (0==time_flags.Trigger_Time_exists_in_all_GPS_sensors)
        nextDataStructure = fcn_TimeClean_recalculateTriggerTimes(nextDataStructure,'gps',fid);
        flag_keep_checking = 0;
    end


    %% ROS_Time Tests
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   _____   ____   _____            _______ _                   _______        _
    %  |  __ \ / __ \ / ____|          |__   __(_)                 |__   __|      | |
    %  | |__) | |  | | (___               | |   _ _ __ ___   ___      | | ___  ___| |_ ___
    %  |  _  /| |  | |\___ \              | |  | | '_ ` _ \ / _ \     | |/ _ \/ __| __/ __|
    %  | | \ \| |__| |____) |             | |  | | | | | | |  __/     | |  __/\__ \ |_\__ \
    %  |_|  \_\\____/|_____/              |_|  |_|_| |_| |_|\___|     |_|\___||___/\__|___/
    %                          ______
    %                         |______|
    %
    % See: http://patorjk.com/software/taag/#p=display&f=Big&t=ROS%20_%20Time%20%20Tests
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Check if ROS_Time_exists_in_all_GPS_sensors
    %    ### ISSUES with this:
    %    * If the sensor is recording data, all data is time-stamped to ROS
    %    time
    %    * The ROS time is aligned with GPS time for sensors that do not have
    %    GPS timebase, and if it is missing, then we cannot use the sensor
    %    ### DETECTION:
    %    * Examine if ROS_Time fields exist on all sensors
    %    ### FIXES:
    %    * Catastrophic error. Sensor has failed and should be removed.
    if (1==flag_keep_checking) && (0==time_flags.ROS_Time_exists_in_all_GPS_sensors)
        warning('on','backtrace');
        warning('Fundamental error on ROS_time: a GPS sensor was found that has no ROS time!?');
        error('Catastrophic failure in one of the sensors in that it is missing ROS time. Stopping.');
    end
    
    %% Check if ROS_Time_scaled_correctly_as_seconds
    %    ### ISSUES with this:
    %    * ROS records time in posix nanoseconds, whereas GPS units records in
    %    posix seconds
    %    * If ROS data is saved in nanoseconds, it causes large scaling
    %    problems.
    %    ### DETECTION:
    %    * Examine if any ROS_Time data is more than 10^8 larger than the
    %    largest GPS_Time data
    %    ### FIXES:
    %    * Divide ROS_Time on this sensor by 10^9, confirm that this fixes the
    %    problem
    if (1==flag_keep_checking) && (0==time_flags.ROS_Time_scaled_correctly_as_seconds)
        nextDataStructure = fcn_TimeClean_convertROSTimeToSeconds(nextDataStructure,'',fid);              
        flag_keep_checking = 0;
    end
    
    %% Check if ROS_Time_sample_modes_match_centiSeconds_in_GPS_sensors
    %    ### ISSUES with this:
    %    * The ROS time and GPS time should both have approximately the same
    %    sampling rates, and we use this alignment to calibrate ROS time to GPS
    %    time absolutely.
    %    * If they do not agree, then either the GPS or the ROS master are
    %    giving wrong data
    %    ### DETECTION:
    %    * Examine if centiSeconds calculation of time interval matches ROS
    %    time interval for data collection, on average
    %    ### FIXES:
    %    * Manually fix, or
    %    * Remove this sensor
    if (1==flag_keep_checking) && (0==time_flags.ROS_Time_sample_modes_match_centiSeconds_in_GPS_sensors)
        warning('on','backtrace');
        warning('Fundamental error on ROS_time: a GPS sensor was found that has a ROS time sample rate different than the GPS sample rate!?');
        error('ROS time is mis-sampled.\');            
        flag_keep_checking = 0;
    end
    

    %% Check if ROS_Time_strictly_ascends_in_GPS_sensors
    %    ### ISSUES with this:
    %    * This field is used to calibrate ROS to GPS time via interpolation, and must
    %    be STRICTLY increasing for the interpolation function to work
    %    * If data packets arrive out-of-order with this sensor, times may not
    %    be in an increasing sequence
    %    * If the ROS topic is glitching, its time may be temporarily incorrect
    %    ### DETECTION:
    %    * Examine if time data from every sensor is STRICTLY increasing
    %    ### FIXES:
    %    * Remove and interpolate time field if not strictly increasing
    %    * Re-order data, if minor ordering error
    if (1==flag_keep_checking) && (0==time_flags.ROS_Time_strictly_ascends_in_GPS_sensors)
        warning('on','backtrace');
        warning('Fundamental error on ROS_time: it is not counting up!?');
        error('ROS time is not strictly ascending.');
        flag_keep_checking = 0;
    end
    

    %% Check if ROS_Time_has_consistent_start_end_across_GPS_sensors
    %    ### ISSUES with this:
    %    * The start times and end times of all data collection assumes all GPS
    %    systems are operating simultaneously
    %    * The calibration of ROS time to GPS time assumes that all start
    %    times are the same, and all end times are the same
    %    * If they are not the same, the count of data in one sensor may be
    %    different than another, especially if each were referencing different
    %    GPS sources.
    %    ### DETECTION:
    %    * Seach through the ROS time fields for all sensors, rounding them to
    %    their appropriate centi-second values
    %    * Check that they all agree
    %    ### FIXES:
    %    * Crop all data to same starting centi-second value

    if (1==flag_keep_checking) && (0==time_flags.ROS_Time_has_consistent_start_end_across_GPS_sensors)
        % Used to create test data
        if 1==1
            fullExampleFilePath = fullfile(cd,'Data','ExampleData_trimDataToCommonStartEndGPSTimes3.mat');
            dataStructure = nextDataStructure;
            save(fullExampleFilePath,'dataStructure');
        end

        field_name = 'ROS_Time';
        sensors_to_check = 'GPS';
        fill_type = 1;
        nextDataStructure = fcn_TimeClean_trimDataToCommonStartEndGPSTimes(nextDataStructure, (field_name), (sensors_to_check), (fill_type), (fid));
        flag_keep_checking = 0;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %    _____      _ _ _               _           _____   ____   _____            _______ _                     _             _____ _____   _____            _______ _
    %   / ____|    | (_) |             | |         |  __ \ / __ \ / ____|          |__   __(_)                   | |           / ____|  __ \ / ____|          |__   __(_)
    %  | |     __ _| |_| |__  _ __ __ _| |_ ___    | |__) | |  | | (___               | |   _ _ __ ___   ___     | |_ ___     | |  __| |__) | (___               | |   _ _ __ ___   ___
    %  | |    / _` | | | '_ \| '__/ _` | __/ _ \   |  _  /| |  | |\___ \              | |  | | '_ ` _ \ / _ \    | __/ _ \    | | |_ |  ___/ \___ \              | |  | | '_ ` _ \ / _ \
    %  | |___| (_| | | | |_) | | | (_| | ||  __/   | | \ \| |__| |____) |             | |  | | | | | | |  __/    | || (_) |   | |__| | |     ____) |             | |  | | | | | | |  __/
    %   \_____\__,_|_|_|_.__/|_|  \__,_|\__\___|   |_|  \_\\____/|_____/              |_|  |_|_| |_| |_|\___|     \__\___/     \_____|_|    |_____/              |_|  |_|_| |_| |_|\___|
    %                                                                      ______                                                                     ______
    %                                                                     |______|                                                                   |______|
    % See http://patorjk.com/software/taag/#p=display&f=Big&t=Calibrate%20%20%20ROS%20_%20Time%20%20%20%20to%20%20%20GPS%20_%20Time
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %% Check if ROS_Time_has_same_length_as_Trigger_Time_in_GPS_sensors
    %    ### ISSUES with this:
    %    * The Trigger_Time represents, for many sensors, when they were
    %    commanded to collect data. If the number of data in the ROS time list
    %    does not match the Trigger_Time length, then this indicates that there
    %    are sensor failures
    %    ### DETECTION:
    %    * Count the number of data in Trigger_Time, and compare it with
    %    ROS_Time - these should match
    %    ### FIXES:
    %    * Remove and interpolate time field if not strictly increasing    
    % Check that ROS_Time data has expected count

    if (1==flag_keep_checking) && (0==time_flags.ROS_Time_has_same_length_as_Trigger_Time_in_GPS_sensors)
        warning('on','backtrace');
        warning('Fundamental error on ROS_time: unexpected count');
        error('ROS time does not have expected count.\');
        flag_keep_checking = 0;
    end


    
    %% Calibrate ROS time to GPS time  ---> ROS_Time_calibrated_to_GPS_Time
    % Perform regression to match ROS time to GPS time.
    %    ### ISSUES with this:
    %    * The ROS time will not match the GPS time. Need to fit GPS time to
    %    ROS time
    %    ### DETECTION:
    %    * (none) assume data is bad by default
    %    ### FIXES:
    %    * Perform regression fit

    if (1==flag_keep_checking) && (0==time_flags.ROS_Time_calibrated_to_GPS_Time)
        % Used to create test data
        if 1==0
            fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
            dataStructure = nextDataStructure;
            save(fullExampleFilePath,'dataStructure');
        end

        [~, ~, ~, mean_fit, filtered_median_errors] =  fcn_TimeClean_fitROSTime2GPSTime(nextDataStructure, (time_flags), (fid), (plotFlags.figNum_fitROSTime2GPSTime));
        flag_keep_checking = 1;
    end


    %% Calculate GPSfromROS_Time in GPS sensors --> GPSfromROS_Time_exists_in_all_GPS_sensors
    % Fills in an estimate of GPS time from ROS time in GPS sensors
    %    ### ISSUES with this:
    %    * The ROS time might not match the GPS time. If there are errors
    %    in the GPS sensors, the same errors are likely in other sensors.
    %    ### DETECTION:
    %    * Make sure the field exists
    %    ### FIXES:
    %    * Calculate GPS time from ROS time via function call

    if (1==flag_keep_checking) && (0==time_flags.GPSfromROS_Time_exists_in_all_GPS_sensors)
        % Used to create test data
        if 1==0
            % fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
            % dataStructure = nextDataStructure;
            % save(fullExampleFilePath,'dataStructure');
        end

        sensors_to_check = 'GPS';
        fid = 1;
        figNum = [];

        nextDataStructure = fcn_TimeClean_fillGPSTimeFromROSTime(mean_fit, filtered_median_errors, nextDataStructure, (sensors_to_check), (fid), (figNum));
        flag_keep_checking = 0; % Force the flags to be recalculated
    end

    %% Fix errors in GPSfromROS_Time_sample_counts_match_centiSeconds_in_GPS_sensors
    %    ### ISSUES with this:
    %    * This field is used to confirm GPSfromROS_Time length matches
    %    expectations from centiSeconds, e.g. the "length" of the vector is
    %    correct
    %    * If the length is wrong, this means that there are missing data
    %    at start end
    %    ### DETECTION:
    %    * calculate the the number of expected samples based on the
    %    centiSeconds. If they are not the same, the start/end needs to be
    %    fixed.
    %    ### FIXES:
    %    * Resample the sensor's start / end values

   
    if (1==flag_keep_checking) && (0==time_flags.GPSfromROS_Time_sample_counts_match_centiSeconds_in_GPS_sensors)

        % Used to create test data
        if 1==0
            fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
            dataStructure = nextDataStructure;
            save(fullExampleFilePath,'dataStructure');
        end
        
        error('This is not programmed yet');
        % nextDataStructure = fcn_TimeClean_recalculateTriggerTimes(nextDataStructure,'gps',fid);
    end


    %% Fix errors in GPSfromROS_Time_sampling_matches_centiSeconds_in_GPS_sensors
    %    ### ISSUES with this:
    %    * This field is used to confirm ROS sampling rates for all
    %    GPS-triggered sensors
    %    * If the ROS sampling interval is wrong, this means that there are
    %    significant amounts of missing data
    %    ### DETECTION:
    %    * calculate the sampling intervals and divide every result by the
    %    expected sampling interval calculated from the intended centiSeconds.
    %    Round this to the nearest integer. To pass, all observed sampling
    %    intervals must round to 1, e.g. that they would have one, and only
    %    one, sample per each sample interval
    %    ### FIXES:
    %    * no need to fix this is just an indicator
   
    if (1==flag_keep_checking) && (0==time_flags.GPSfromROS_Time_sampling_matches_centiSeconds_in_GPS_sensors)

        % Used to create test data
        if 1==0
            fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
            dataStructure = nextDataStructure;
            save(fullExampleFilePath,'dataStructure');
        end

        % Swap data
        badSensorNames = regexp(offending_sensor,' ','split');    
        for ith_bad = 1:length(badSensorNames)
            this_sensor = badSensorNames{ith_bad};
            nextDataStructure.(this_sensor).GPSfromROS_Time = nextDataStructure.(this_sensor).Trigger_Time;
        end
        flag_keep_checking = 0; % Force the flags to be recalculated
    end

    %% ALL SENSORS STARTS HERE
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %   _____      _ _ _               _                    _ _      _____                                  _          _______   _                          _______ _
    %  / ____|    | (_) |             | |             /\   | | |    / ____|                                | |        |__   __| (_)                        |__   __(_)
    % | |     __ _| |_| |__  _ __ __ _| |_ ___       /  \  | | |   | (___   ___ _ __  ___  ___  _ __ ___   | |_ ___      | |_ __ _  __ _  __ _  ___ _ __      | |   _ _ __ ___   ___
    % | |    / _` | | | '_ \| '__/ _` | __/ _ \     / /\ \ | | |    \___ \ / _ \ '_ \/ __|/ _ \| '__/ __|  | __/ _ \     | | '__| |/ _` |/ _` |/ _ \ '__|     | |  | | '_ ` _ \ / _ \
    % | |___| (_| | | | |_) | | | (_| | ||  __/    / ____ \| | |    ____) |  __/ | | \__ \ (_) | |  \__ \  | || (_) |    | | |  | | (_| | (_| |  __/ |        | |  | | | | | | |  __/
    %  \_____\__,_|_|_|_.__/|_|  \__,_|\__\___|   /_/    \_\_|_|   |_____/ \___|_| |_|___/\___/|_|  |___/   \__\___/     |_|_|  |_|\__, |\__, |\___|_|        |_|  |_|_| |_| |_|\___|
    %                                                                                                                               __/ | __/ |
    %                                                                                                                              |___/ |___/
    % See: http://patorjk.com/software/taag/#p=display&f=Big&t=Calibrate%20%20%20All%20%20%20Sensors%20%20to%20Trigger%20%20Time
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Make sure centieconds in all

    %% Check if centiSeconds_exists_in_all_sensors
    %    ### ISSUES with this:
    %    * This field defines the expected sample rate for each sensor
    %    ### DETECTION:
    %    * Examine if centiSeconds fields exist on all sensors
    %    ### FIXES:
    %    * Manually fix, or
    %    * Remove this sensor

    if (1==flag_keep_checking) && (0==time_flags.centiSeconds_exists_in_all_GPS_sensors)
        disp(nextDataStructure.(offending_sensor))
        warning('on','backtrace');
        warning('Fundamental error on GPS_time: a GPS sensor is missing centiSeconds!?');
        error('Catastrophic data error detected: the following GPS sensor is missing centiSeconds: %s.',offending_sensor);
    end

    %% Check if ROS_Time_has_no_repeats_in_all_sensors
    %    ### ISSUES with this:
    %    * If there are any repeated time values, the interpolation in
    %    later steps will break
    %    ### DETECTION:
    %    * Examine if time values are unique
    %    ### FIXES:
    %    * Remove repeats

    if (1==flag_keep_checking) && (0==time_flags.ROS_Time_has_no_repeats_in_all_sensors)
        % Fix the data
        warning('on','backtrace');
        warning('This code section probably works, but has not been tested.');
        field_name = 'ROS_Time';
        sensors_to_check = [];
        nextDataStructure = fcn_TimeClean_trimRepeatsFromField(nextDataStructure,fid, field_name,sensors_to_check);
        flag_keep_checking = 0;
    end
    
    %% Check if ROS_Time_strictly_ascends_in_all_sensors
    %    ### ISSUES with this:
    %    * This field is used to calibrate ROS to GPS time via interpolation, and must
    %    be STRICTLY increasing for the interpolation function to work
    %    * If data packets arrive out-of-order with this sensor, times may not
    %    be in an increasing sequence
    %    * If the ROS topic is glitching, its time may be temporarily incorrect
    %    ### DETECTION:
    %    * Examine if time data from every sensor is STRICTLY increasing
    %    ### FIXES:
    %    * Remove and interpolate time field if not strictly increasing
    %    * Re-order data, if minor ordering error
    if (1==flag_keep_checking) && (0==time_flags.ROS_Time_strictly_ascends_in_all_sensors)
        warning('on','backtrace');
        warning('Fundamental error on ROS_time: it is not counting up!?');
        error('ROS time is not strictly ascending.');
        flag_keep_checking = 0;
    end
    
    %% Calculate GPSfromROS_Time in all sensors --> GPSfromROS_Time_exists_in_all_sensors
    % Fills in an estimate of GPS time from ROS time in all sensors
    %    ### ISSUES with this:
    %    * The ROS time might not match the GPS time. If there are errors
    %    in the GPS sensors, the same errors are likely in other sensors.
    %    ### DETECTION:
    %    * Make sure the field exists
    %    ### FIXES:
    %    * Calculate GPS time from ROS time via function call
    if (1==flag_keep_checking) && (0==time_flags.GPSfromROS_Time_exists_in_all_sensors)
        % Used to create test data
        if 1==0
            % fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
            % dataStructure = nextDataStructure;
            % save(fullExampleFilePath,'dataStructure');
        end

        sensors_to_check = [];
        fid = 1;
        figNum = [];

        nextDataStructure = fcn_TimeClean_fillGPSTimeFromROSTime(mean_fit, filtered_median_errors, nextDataStructure, (sensors_to_check), (fid), (figNum));
        flag_keep_checking = 0; % Force the flags to be recalculated
    end
    
    %% Check if GPSfromROS_Time_has_consistent_start_end_across_all_sensors
    %    ### ISSUES with this:
    %    * The start times and end times of all data collection assumes all GPS
    %    systems are operating simultaneously
    %    * The calculation of Trigger_Time assumes that all start times are the
    %    same, and all end times are the same
    %    * If they are not the same, the count of data in one sensor may be
    %    different than another, especially if each were referencing different
    %    GPS sources.
    %    ### DETECTION:
    %    * Seach through the GPS time fields for all sensors, rounding them to
    %    their appropriate centi-second values
    %    * Check that they all agree
    %    ### FIXES:
    %    * Crop all data to same starting centi-second value

    if (1==flag_keep_checking) && (0==time_flags.GPSfromROS_Time_has_consistent_start_end_across_all_sensors)
        % Used to create test data
        if 1==0
            fullExampleFilePath = fullfile(cd,'Data','ExampleData_trimDataToCommonStartEndGPSTimes2.mat');
            dataStructure = nextDataStructure;
            save(fullExampleFilePath,'dataStructure');
        end

        field_name = 'GPSfromROS_Time';
        sensors_to_check = [];
        fill_type = 1;
        nextDataStructure = fcn_TimeClean_trimDataToCommonStartEndGPSTimes(nextDataStructure, (field_name), (sensors_to_check), (fill_type), (fid));
        [startTimes,sensorsToTrim_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(nextDataStructure, 'GPSfromROS_Time', [],'first_row');
        
        flag_keep_checking = 0;
    end



    %% Check if Trigger_Time_exists_in_all_sensors
    %    ### ISSUES with this:
    %    * This field is used to assign data collection timings for all
    %    non-GPS-triggered sensors, and to fill in GPS_Time data if there's a
    %    short outage
    %    * These sensors may be configured wrong
    %    * These sensors may be faililng or operating incorrectly
    %    ### DETECTION:
    %    * Examine if Trigger_Time fields exist
    %    ### FIXES:
    %    * Recalculate Trigger_Time fields as needed, using centiSecond
    if (1==flag_keep_checking) && (0==time_flags.Trigger_Time_exists_in_all_sensors)
        nextDataStructure = fcn_TimeClean_recalculateTriggerTimes(nextDataStructure,[],fid);
        flag_keep_checking = 0;
    end

    %%


  
    % %% Start to work on other sensors, start with Velodyne LiDAR
    % if (1==flag_keep_checking) && (flag_all_trigger_time_calculated==1)
    %     % figure(123)
    %     % plot(nextDataStructure.GPS_SparkFun_Front.Trigger_Time)
    %     % hold on
    %     % plot(nextDataStructure.LiDAR_Velodyne_Rear.Trigger_Time)
    %     % plot(nextDataStructure.TRIGGER_TrigBox_RearTop.Trigger_Time)
    %     nextDataStructure = fcn_TimeClean_trimDataToCommonStartEndTriggerTimes(nextDataStructure,fid);
    %     flag_keep_checking = 0;
    %     % figure(124)
    %     % plot(nextDataStructure.GPS_SparkFun_Front.Trigger_Time)
    %     % hold on
    %     % plot(nextDataStructure.LiDAR_Velodyne_Rear.Trigger_Time)
    %     % 
    % end

   


    %% Done? Check Exiting conditions
    % if length(dataset)==1
    %     temp = dataset;
    %     clear dataset
    %     dataset{1} = temp;
    % end


    currentDataStructure = nextDataStructure;
    currentDataStructure.Identifiers = Identifiers_Hold;
      
    % Check all the time_flags, so we can exit!
    flag_stay_in_main_loop = fcn_INTERNAL_checkFlagsForExit(time_flags);
    
    % Have we done too many loops?
    if main_data_clean_loop_iteration_number>N_max_loops
        flag_stay_in_main_loop = 0;
    end
          
end

main_data_clean_loop_iteration_number = main_data_clean_loop_iteration_number+1;
debugging_data_structure_sequence{main_data_clean_loop_iteration_number} = currentDataStructure; %#ok<NASGU>
cleanDataStruct = currentDataStructure;
subPathStrings = '';

%%
fprintf(fid,'Cleaning completed\n');

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
if (1==flag_do_plots)

    if fid
        fprintf(fid,'\nBEGINNING PLOTTING: \n');
    end


    %% Save plotted images?
    if ~isempty(plotFlags.figNum_checkTimeSamplingConsistency_GPSTime)
        % Save the image to file?
        if 1==saveFlags.flag_saveImages
            figure(plotFlags.figNum_checkTimeSamplingConsistency_GPSTime);
            fcn_INTERNAL_saveImages(cat(2,'cleanTime_GPS_',Identifiers.WorkZoneScenario), saveFlags);
        end

    end

    if  ~isempty(plotFlags.figNum_checkTimeSamplingConsistency_ROSTime)
        % Save the image to file?
        if 1==saveFlags.flag_saveImages
            figure(plotFlags.figNum_checkTimeSamplingConsistency_ROSTime);
            fcn_INTERNAL_saveImages(cat(2,'cleanTime_ROS_',Identifiers.WorkZoneScenario), saveFlags);
        end

    end



    % %% Save mat file?
    % if ~isempty(plotFlags.figNum_checkTimeSamplingConsistency_ROSTime)
    %     % Save the mat file?
    %     if 1 == saveFlags.flag_saveMatFile
    %         fcn_INTERNAL_saveMATfile(rawDataCellArray{ith_rawData}, char(bagName_clean), saveFlags);
    %     end
    % end



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


%% fcn_INTERNAL_checkFlagsForExit
function flag_stay_in_main_loop = fcn_INTERNAL_checkFlagsForExit(flags)
flag_fields = fieldnames(flags); % Grab all the flags
flag_array = zeros(length(flag_fields),1);
for ith_field = 1:length(flag_fields)
    flag_array(ith_field,1) = flags.(flag_fields{ith_field});
end

flag_stay_in_main_loop = 1;
if all(flag_array==1)
    flag_stay_in_main_loop = 0;
end
end % Ends fcn_INTERNAL_checkFlagsForExit


%% fcn_INTERNAL_reportFlagStatus
function fcn_INTERNAL_reportFlagStatus(flagStructure,printTitle)
fprintf(1,'\n%s\n',printTitle);
fieldsToprint = fieldnames(flagStructure);
NcharactersField = 50;
for ith_field = 1:length(fieldsToprint)
    thisField = fieldsToprint{ith_field};
    formattedHeaderString  = fcn_DebugTools_debugPrintStringToNCharacters(thisField,NcharactersField);
    fprintf(1,'%s\t',formattedHeaderString);
    fieldValue = flagStructure.(thisField);
    if 1==fieldValue
        fieldString = 'yes';
    else
        fieldString = 'no';
    end
    fprintf(1,'%s\n',fieldString);    
end
fprintf(1,'\n');
end % Ends fcn_INTERNAL_reportFlagStatus


%% fcn_INTERNAL_saveImages
function fcn_INTERNAL_saveImages(imageName, saveFlags)

pause(2); % Wait 2 seconds so that images can load

Image = getframe(gcf);
PNG_image_fname = cat(2,imageName,'.png');
PNG_imagePath = fullfile(saveFlags.flag_saveImages_directory,PNG_image_fname);
if 2~=exist(PNG_imagePath,'file') || 1==saveFlags.flag_forceImageOverwrite
    imwrite(Image.cdata, PNG_imagePath);
end

FIG_image_fname = cat(2,imageName,'.fig');
FIG_imagePath = fullfile(saveFlags.flag_saveImages_directory,FIG_image_fname);
if 2~=exist(FIG_imagePath,'file') || 1==saveFlags.flag_forceImageOverwrite
    savefig(FIG_imagePath);
end
end % Ends fcn_INTERNAL_saveImages

%% fcn_INTERNAL_saveMATfile
function  fcn_INTERNAL_saveMATfile(rawData, MATfileName, saveFlags)

MAT_fname = cat(2,MATfileName,'.mat');
MAT_fullPath = fullfile(saveFlags.flag_saveMatFile_directory,MAT_fname);
if 2~=exist(MAT_fullPath,'file') || 1==saveFlags.flag_forceMATfileOverwrite
    save(MAT_fullPath,'rawData');
end

end % Ends fcn_INTERNAL_saveMATfile
