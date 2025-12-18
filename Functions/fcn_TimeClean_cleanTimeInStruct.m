function [cleanDataStruct, subPathStrings]  = fcn_TimeClean_cleanTimeInStruct(rawDataStruct, varargin)
% fcn_TimeClean_cleanTimeInStruct
% given a raw data structure, cleans time jumps, time out-of-ordering, and
% time alignment between ROS and GPS time
%
% FORMAT:
%
%      cleanDataStruct = fcn_TimeClean_cleanTimeInStruct(rawDataStruct, (fid), (Flags), (saveFlags), (plotFlags))
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
%     See the script: script_test_fcn_TimeClean_cleanTimeInStruct
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
% As: fcn_TimeClean_cleanTimeInStruct
%
% 2025_11_25 by Sean Brennan, sbrennan@psu.edu
% - Renamed function to better distinguish that it is operating only on a
%   % structure input, not as a full directory-level clean
%   % From: fcn_TimeClean_cleanTime
%   % To: fcn_TimeClean_cleanTimeInStruct
%
% 2025_12_17 by Sean Brennan, sbrennan@psu.edu
% - Made some of the test cases more verbose
% - Fixed errors in printing where print-to-fid was not working

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
saveFlags.flag_saveImages_directory = ''; %#ok<STRNU>
if 4 <= nargin
    temp = varargin{3};
    if ~isempty(temp)
        saveFlags = temp; %#ok<NASGU>
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

timeFlags = struct;

%%
fprintf(1, 'Iteration (of 5 max): ')
fprintf(1,'%.0f ', main_data_clean_loop_iteration_number);
while 1==flag_stay_in_main_loop
    fcn_INTERNAL_printChecking(fid,'*blue','\n');
    fcn_INTERNAL_printChecking(fid,'*blue','Checking for timing errors: ');

    %% Keep data thus far
    main_data_clean_loop_iteration_number = main_data_clean_loop_iteration_number+1;
    fprintf(1,'%.0f ', main_data_clean_loop_iteration_number);

    debugging_data_structure_sequence{main_data_clean_loop_iteration_number} = currentDataStructure;

    fcn_INTERNAL_printChecking(fid,'*blue','\n\n ----------------------------------------------------------------------------------------------------------------\n');
    fcn_INTERNAL_printChecking(fid,'*blue',sprintf('Time Cleaning Iteration #%.0d\n',main_data_clean_loop_iteration_number));


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

    oldTimeFlags = timeFlags;
    % if (1==flag_keep_checking)
    %     % [timeFlags, offending_sensor] = fcn_TimeClean_checkDataTimeConsistency(nextDataStructure, fid, plotFlags);
    %     % if ~isempty(offending_sensor) && 0~=fid
    %     %     fprintf(fid,'\tOffending sensor: %s\n', offending_sensor);
    %     % end
    % end

    fcn_INTERNAL_reportFlagStatus(timeFlags,'TIMING FLAGS', fid);



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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: GPS_Time_exists_in_at_least_one_GPS_sensor \n');

    [timeFlags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(nextDataStructure,'GPS_Time',timeFlags,'any','GPS',fid);

    if (1==flag_keep_checking) && (0==timeFlags.GPS_Time_exists_in_at_least_one_GPS_sensor)
        fcn_INTERNAL_printChecking(fid,'*red','FAIL\n');
        warning('on','backtrace');
        warning('Fundamental error on GPS_time: no sensors detected that have GPS time!?');
        error('Catastrophic data error detected: no GPS_Time data detected in any sensor. Offending sensor: %s.', offending_sensor);
    end
    fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');


    %% Check if GPS_Time_exists_in_all_GPS_sensors
    %    ### ISSUES with this:
    %    * There is no absolute time base to use for the sensor
    %    * This usually indicates back lock for the GPS
    %    ### DETECTION:
    %    * Examine if GPS time fields exist on all GPS sensors
    %    ### FIXES:
    %    * If another GPS is available, use its time alongside the GPS data
    %    * Remove this GPS data field

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: GPS_Time_exists_in_all_GPS_sensors  \n');

    [timeFlags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(nextDataStructure,'GPS_Time',timeFlags,'all','GPS',fid);

    if (1==flag_keep_checking) && (0==timeFlags.GPS_Time_exists_in_all_GPS_sensors)
        fcn_INTERNAL_printChecking(fid,'*red','FAIL\n');
        warning('on','backtrace');
        warning('Fundamental error on GPS_time: a GPS sensor is missing GPS time!?');
        error('Catastrophic data error detected: the following GPS sensor is missing GPS_Time data: %s.',offending_sensor);
    end

    fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');


    %% Check if centiSeconds_exists_in_all_GPS_sensors
    %    ### ISSUES with this:
    %    * This field defines the expected sample rate for each sensor
    %    ### DETECTION:
    %    * Examine if centiSeconds fields exist on all sensors
    %    ### FIXES:
    %    * Manually fix, or
    %    * Remove this sensor

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: centiSeconds_exists_in_all_GPS_sensors  \n');

    [timeFlags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(nextDataStructure,'centiSeconds',timeFlags,'all','GPS',fid);


    if (1==flag_keep_checking) && (0==timeFlags.centiSeconds_exists_in_all_GPS_sensors)
        fcn_INTERNAL_printChecking(fid,'*red','FAIL\n');
        disp(nextDataStructure.(offending_sensor))
        warning('on','backtrace');
        warning('Fundamental error on GPS_time: a GPS sensor is missing centiSeconds!?');
        error('Catastrophic data error detected: the following GPS sensor is missing centiSeconds: %s.',offending_sensor);
    end

    fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');



    %% Check if GPS_Time_has_no_repeats_in_GPS_sensors
    %    ### ISSUES with this:
    %    * If there are many repeated time values, the calculation of sampling
    %    time in the future steps produces incorrect results
    %    ### DETECTION:
    %    * Examine if time values are unique
    %    ### FIXES:
    %    * Remove repeats



    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: GPS_Time_has_no_repeats_in_GPS_sensors  \n');

    [timeFlags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(nextDataStructure,'GPS_Time',timeFlags, 'GPS', (fid),(-1));

    if (1==flag_keep_checking) && (0==timeFlags.GPS_Time_has_no_repeats_in_GPS_sensors)
        % Fix the data
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found repeated GPS_Time values in sensor: %s \n\tAttempting a fix... ', offending_sensor));

        field_name = 'GPS_Time';
        sensors_to_check = 'GPS';
        nextDataStructure = fcn_TimeClean_trimRepeatsFromField(nextDataStructure,fid, field_name,sensors_to_check);

        % Did it work?
        [timeFlags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(nextDataStructure,'GPS_Time',timeFlags, 'GPS', (fid),(-1));

        if (1==timeFlags.GPS_Time_has_no_repeats_in_GPS_sensors)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1;
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: repeated GPS_Time values found in sensor %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: GPS_Time_sample_modes_match_centiSeconds_in_GPS_sensors  \n');

    verificationTypeFlag = 0; 
    [timeFlags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(nextDataStructure,'GPS_Time', verificationTypeFlag, timeFlags, 'GPS',fid, plotFlags.figNum_checkTimeSamplingConsistency_GPSTime);

    if (1==flag_keep_checking) && (0==timeFlags.GPS_Time_sample_modes_match_centiSeconds_in_GPS_sensors)
        fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: GPS_Time sampling rate does not match centiSeconds in sensor %s\n', offending_sensor));
        error('Inconsistent data detected: the following GPS sensor has an average sampling rate different than predicted from centiSeconds: %s.',offending_sensor);
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: GPS_Time_strictly_ascends_in_GPS_sensors  \n');

    [timeFlags, offending_sensor,~] = fcn_TimeClean_checkDataStrictlyIncreasing(nextDataStructure, 'GPS_Time', (timeFlags), ('GPS'), (fid), ([]));

    if (1==flag_keep_checking) && (0==timeFlags.GPS_Time_strictly_ascends_in_GPS_sensors)
        % Fix the data
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found repeated GPS_Time values that are out of order in sensor: %s \n\tAttempting a fix... ', offending_sensor));

        field_name = 'GPS_Time';
        sensors_to_check = 'GPS';
        nextDataStructure = fcn_TimeClean_sortSensorDataByGPSTime(nextDataStructure, field_name,sensors_to_check,fid);

        % Did it work?
        [timeFlags, offending_sensor,~] = fcn_TimeClean_checkDataStrictlyIncreasing(nextDataStructure, 'GPS_Time', (timeFlags), ('GPS'), (fid), ([]));

        if (1==timeFlags.GPS_Time_strictly_ascends_in_GPS_sensors)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1;
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: GPS_Time out-of-ordering found in sensor %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
    end


    %% Check if GPS_Time_has_consistent_start_end_within_5_seconds
    %    ### ISSUES with this:
    %    * The start times and end times of all data collection assumes all GPS
    %    systems are operating simultaneously
    %    * The calculation of Trigger_Time assumes that all start times are the
    %    same, and all end times are the same
    %    * If they are not the same, the count of data in one sensor may be
    %    different than another, especially if each were referencing different
    %    GPS sources.
    %    * The start times of all sensors in general should be the same,
    %    within a few seconds, as this is the boot-up time for sensors
    %    * If the times are severely wrong, this can indicate that the
    %    sensors are giving bad data
    %    * As an example, on 2023_06_22, a new GPS antenna installed on the
    %    mapping van produced time that was not UTC, but EST, resulting in
    %    a 4-hour (!!!) difference in start times
    %    ### DETECTION:
    %    * Seach through the GPS time fields for all sensors, rounding them to
    %    their appropriate centi-second values
    %    * Check that they all agree within 5 seconds
    %    ### FIXES:
    %    * Use GPS sensors to "vote" on actual start time. For outliers,
    %    try different time shifts to minimize error. If error is reduced
    %    to less than 5 seconds, then the fix worked. Otherwise, throw an
    %    error.
    %    * Crop all data to same starting centi-second value

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: GPS_Time_has_consistent_start_end_within_5_seconds  \n');

    [timeFlags, offending_sensor, ~] = fcn_TimeClean_checkConsistencyOfStartEnd(nextDataStructure, 'GPS_Time', (timeFlags), ('GPS'), ('_within_5_seconds'), (5.0), (fid), ([]));


    if (1==flag_keep_checking) && (0==timeFlags.GPS_Time_has_consistent_start_end_within_5_seconds)
        % Fix the data
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found starting GPS_Time values between sensors that are more than 5 seconds apart, for example in sensor: %s \n\tAttempting a fix... ', offending_sensor));

        nextDataStructure = fcn_TimeClean_correctTimeZoneErrorsInGPSTime(nextDataStructure,fid);

        % Did it work?
        [timeFlags, offending_sensor, ~] = fcn_TimeClean_checkConsistencyOfStartEnd(nextDataStructure, 'GPS_Time', (timeFlags), ('GPS'), ('_within_5_seconds'), (5.0), (fid), ([]));

        if (1==timeFlags.GPS_Time_has_consistent_start_end_within_5_seconds)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1;
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: GPS_Time offsets do not seem to be fixable. %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
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
    %    * Seach through the GPS time fields for all sensors, making sure all
    %    would round to their appropriate centi-second values (at 20 Hz, this
    %    is rounding to 0.05 seconds, so all should be within 0.025 seconds)
    %    * Check that they all agree
    %    ### FIXES:
    %    * Crop all data to same starting centi-second value

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: GPS_Time_has_consistent_start_end_across_GPS_sensors  \n');

    [timeFlags, offending_sensor, ~] = fcn_TimeClean_checkConsistencyOfStartEnd(nextDataStructure, 'GPS_Time', (timeFlags), ('GPS'), ('_across_GPS_sensors'), (.025), (fid), ([]));

    if (1==flag_keep_checking) && (0==timeFlags.GPS_Time_has_consistent_start_end_across_GPS_sensors)
        % Fix the data
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found starting GPS_Time values between sensors that start at different times, for example in sensor: %s \n\tAttempting a fix... ', offending_sensor));

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


        % Did it work?
        [timeFlags, offending_sensor, ~] = fcn_TimeClean_checkConsistencyOfStartEnd(nextDataStructure, 'GPS_Time', (timeFlags), ('GPS'), ('_across_GPS_sensors'), (.025), (fid), ([]));

        if (1==timeFlags.GPS_Time_has_consistent_start_end_across_GPS_sensors)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1;
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: GPS_Time start and/or end could not be matched in at least one sensor, for example %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: GPS_Time_has_no_sampling_jumps_in_any_GPS_sensors  \n');


    threshold_in_standard_deviations = 5;
    custom_lower_threshold = 0.0001; % Time steps cannot be smaller than this
    [timeFlags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(...
        nextDataStructure,'GPS_Time',timeFlags,threshold_in_standard_deviations, custom_lower_threshold,'any','GPS', fid);

    if (1==flag_keep_checking) && (0==timeFlags.GPS_Time_has_no_sampling_jumps_in_any_GPS_sensors)
        % Used to create test data
        if 1==0
            fullExampleFilePath = fullfile(cd,'Data','ExampleData_fillMissingsInGPSUnits.mat');
            dataStructure = nextDataStructure;
            save(fullExampleFilePath,'dataStructure');
        end
        nextDataStructure = fcn_TimeClean_fillMissingsInGPSUnits(nextDataStructure, fid);
        flag_keep_checking = 0;
    end


    if (1==flag_keep_checking) && (0==timeFlags.GPS_Time_has_no_sampling_jumps_in_any_GPS_sensors)
        % Fix the data
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found sampling jumps in a GPS sensor, in sensor: %s \n\tAttempting a fix... ', offending_sensor));

        % Used to create test data
        if 1==0
            fullExampleFilePath = fullfile(cd,'Data','ExampleData_fillMissingsInGPSUnits.mat');
            dataStructure = nextDataStructure;
            save(fullExampleFilePath,'dataStructure');
        end
        nextDataStructure = fcn_TimeClean_fillMissingsInGPSUnits(nextDataStructure, fid);

        % Did it work?
        [timeFlags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(...
            nextDataStructure,'GPS_Time',timeFlags,threshold_in_standard_deviations, custom_lower_threshold,'any','GPS', fid);

        if (1==timeFlags.GPS_Time_has_no_sampling_jumps_in_any_GPS_sensors)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1;
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: GPS_Time after fix still has sampling jumps in at least one sensor, for example %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
    end


    %% Check if GPS_Time_has_no_missing_sample_differences_in_any_GPS_sensors
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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: GPS_Time_has_no_missing_sample_differences_in_any_GPS_sensors  \n');

    threshold_for_agreement = 0.0001; % Data must agree within this interval
    expectedJump = []; % Forces default to centiSeconds*0.01
    string_any_or_all = 'any';
    sensors_to_check = 'GPS';

    % Check if an error is detected
    [timeFlags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(...
        nextDataStructure, 'GPS_Time', (timeFlags), (threshold_for_agreement), (expectedJump), (string_any_or_all), (sensors_to_check), (fid));


    if (1==flag_keep_checking) && (0==timeFlags.GPS_Time_has_no_missing_sample_differences_in_any_GPS_sensors)
        % Fix the data
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found missing time samples in a GPS sensor, in sensor: %s \n\tAttempting a fix... ', offending_sensor));

        % Used to create test data
        if 1==0
            % fullExampleFilePath = fullfile(cd,'Data','ExampleData_fillMissingsInGPSUnits.mat');
            % dataStructure = nextDataStructure;
            % save(fullExampleFilePath,'dataStructure');
        end
        nextDataStructure = fcn_TimeClean_fillMissingsInGPSUnits(nextDataStructure, fid);

        % Did it work?
        [timeFlags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(...
            nextDataStructure, 'GPS_Time', (timeFlags), (threshold_for_agreement), (expectedJump), (string_any_or_all), (sensors_to_check), (fid));

        if (1==timeFlags.GPS_Time_has_no_missing_sample_differences_in_any_GPS_sensors)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1;
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: GPS_Time after fix still has sampling differences in at least one sensor, for example %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: Trigger_Time_exists_in_all_GPS_sensors  \n');

    [timeFlags,offending_sensor,~] = fcn_TimeClean_checkIfFieldInSensors(nextDataStructure,'Trigger_Time',timeFlags,'all','GPS',fid);

    if (1==flag_keep_checking) && (0==timeFlags.Trigger_Time_exists_in_all_GPS_sensors)
        % Fix the data
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found missing Trigger_Time in a GPS sensor, in sensor: %s \n\tAttempting a fix... ', offending_sensor));

        % Used to create test data
        if 1==0
            % fullExampleFilePath = fullfile(cd,'Data','ExampleData_fillMissingsInGPSUnits.mat');
            % dataStructure = nextDataStructure;
            % save(fullExampleFilePath,'dataStructure');
        end
        nextDataStructure = fcn_TimeClean_recalculateTriggerTimes(nextDataStructure,'gps',-1);

        % Did it work?
        [timeFlags,offending_sensor,~] = fcn_TimeClean_checkIfFieldInSensors(nextDataStructure,'Trigger_Time',timeFlags,'all','GPS',fid);

        if (1==timeFlags.Trigger_Time_exists_in_all_GPS_sensors)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1;
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: Trigger_Time missing in at least one GPS sensor, for example %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: ROS_Time_exists_in_all_GPS_sensors  \n');


    [timeFlags,offending_sensor,~] = fcn_TimeClean_checkIfFieldInSensors(nextDataStructure,'ROS_Time',timeFlags,'all','GPS',fid);

    if (1==flag_keep_checking) && (0==timeFlags.ROS_Time_exists_in_all_GPS_sensors)
        fcn_INTERNAL_printChecking(fid,'*red','FAIL\n');
        warning('on','backtrace');
        warning('Fundamental error on ROS_time: a GPS sensor was found that has no ROS time!? Sensor name: %s', offending_sensor);
        error('Catastrophic failure in one of the sensors in that it is missing ROS time. Stopping.');
    end

    fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');

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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: ROS_Time_scaled_correctly_as_seconds  \n');

    [timeFlags,offending_sensor,~] = fcn_INTERNAL_checkIfROSTimeMisScaled(fid, nextDataStructure, timeFlags);

    if (1==flag_keep_checking) && (0==timeFlags.ROS_Time_scaled_correctly_as_seconds)
        % Fix the data
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found incorrectly scaled ROS time in a GPS sensor, in sensor: %s \n\tAttempting a fix... ', offending_sensor));

        % Used to create test data
        if 1==0
            % fullExampleFilePath = fullfile(cd,'Data','ExampleData_fillMissingsInGPSUnits.mat');
            % dataStructure = nextDataStructure;
            % save(fullExampleFilePath,'dataStructure');
        end
        nextDataStructure = fcn_TimeClean_convertROSTimeToSeconds(nextDataStructure,'',fid);

        % Did it work?
        [timeFlags,offending_sensor,~] = fcn_INTERNAL_checkIfROSTimeMisScaled(fid, nextDataStructure, timeFlags);

        if (1==timeFlags.ROS_Time_scaled_correctly_as_seconds)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1;
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: ROS_time is still not correctly scaled in at least one GPS sensor, for example %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: ROS_Time_sample_modes_match_centiSeconds_in_GPS_sensors  \n');

    % Below uses plotFlags.figNum_checkTimeSamplingConsistency_ROSTime
    verificationTypeFlag = 0;
    [timeFlags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(nextDataStructure,'ROS_Time', verificationTypeFlag, timeFlags, 'GPS',fid, plotFlags.figNum_checkTimeSamplingConsistency_ROSTime);


    if (1==flag_keep_checking) && (0==timeFlags.ROS_Time_sample_modes_match_centiSeconds_in_GPS_sensors)
        fcn_INTERNAL_printChecking(fid,'*red','FAIL\n');
        warning('on','backtrace');
        warning('Fundamental error on ROS_time: a GPS sensor was found that has a ROS time sample rate different than the GPS sample rate!? Sensor name: %s',offending_sensor);
        error('ROS time is mis-sampled.\');
        flag_keep_checking = 0;
    end

    fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');

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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: ROS_Time_strictly_ascends_in_GPS_sensors  \n');

    [timeFlags,offending_sensor,~] = fcn_TimeClean_checkDataStrictlyIncreasing(nextDataStructure, 'ROS_Time', (timeFlags), ('GPS'), (fid), ([]));

    if (1==flag_keep_checking) && (0==timeFlags.ROS_Time_strictly_ascends_in_GPS_sensors)
        fcn_INTERNAL_printChecking(fid,'*red','FAIL\n');
        warning('on','backtrace');
        warning('Fundamental error on ROS_time: it is not counting up!? Sensor name: %s', offending_sensor);
        error('ROS time is not strictly ascending.');
        flag_keep_checking = 0;
    end

    fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');

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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: ROS_Time_has_consistent_start_end_across_GPS_sensors  \n');

    % Check ROS_Time_has_consistent_start_end_across_GPS_sensors
    [allCentiSeconds, ~] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(nextDataStructure, 'centiSeconds', 'GPS');
    maxSamplingIntervalCentiSeconds = max(cell2mat(allCentiSeconds'));
    [timeFlags, offending_sensor, ~] = fcn_TimeClean_checkConsistencyOfStartEnd(nextDataStructure, 'ROS_Time', (timeFlags), ('GPS'), ('_across_GPS_sensors'), (maxSamplingIntervalCentiSeconds*0.01/2), (fid), ([]));


    if (1==flag_keep_checking) && (0==timeFlags.ROS_Time_has_consistent_start_end_across_GPS_sensors)
        % Fix the data
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found ROS time with inconsistent start or stop, in sensor: %s \n\tAttempting a fix... ', offending_sensor));

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

        % Did it work?
        [timeFlags, offending_sensor, ~] = fcn_TimeClean_checkConsistencyOfStartEnd(nextDataStructure, 'ROS_Time', (timeFlags), ('GPS'), ('_across_GPS_sensors'), (maxSamplingIntervalCentiSeconds*0.01/2), (fid), ([]));

        if (1==timeFlags.ROS_Time_has_consistent_start_end_across_GPS_sensors)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1;
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: ROS_time is still has inconsistent start or stop, in sensor: %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: ROS_Time_has_same_length_as_Trigger_Time_in_GPS_sensors  \n');

    [timeFlags,offending_sensor,~]  = fcn_TimeClean_checkFieldCountMatchesTimeCount(nextDataStructure,'ROS_Time',timeFlags,'Trigger_Time','GPS',fid);

    if (1==flag_keep_checking) && (0==timeFlags.ROS_Time_has_same_length_as_Trigger_Time_in_GPS_sensors)
        fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL - ROS_Time is not same length as Trigger_time in GPS sensor: %s\n', offending_sensor));
        warning('on','backtrace');
        warning('Fundamental error on ROS_time: unexpected count');
        error('ROS time does not have expected count.\');
        flag_keep_checking = 0;
    end

    fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');

    %% Calibrate ROS time to GPS time  ---> ROS_Time_calibrated_to_GPS_Time
    % Perform regression to match ROS time to GPS time.
    %    ### ISSUES with this:
    %    * The ROS time will not match the GPS time. Need to fit GPS time to
    %    ROS time
    %    ### DETECTION:
    %    * (none) assume data is bad by default
    %    ### FIXES:
    %    * Perform regression fit

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: ROS_Time_calibrated_to_GPS_Time  \n');

    timeFlags.ROS_Time_calibrated_to_GPS_Time = 0;

    if (1==flag_keep_checking) && (0==timeFlags.ROS_Time_calibrated_to_GPS_Time)
        % Used to create test data
        if 1==0
            fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
            dataStructure = nextDataStructure;
            save(fullExampleFilePath,'dataStructure');
        end

        if 1==0
            fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime_TestCase20001.mat');
            dataStructure = nextDataStructure;
            save(fullExampleFilePath,'dataStructure');
        end

        [~, ~, ~, mean_fit, filtered_median_errors] =  fcn_TimeClean_fitROSTime2GPSTime(nextDataStructure, (timeFlags), (fid), (plotFlags.figNum_fitROSTime2GPSTime));
        flag_keep_checking = 1;
    end

    timeFlags.ROS_Time_calibrated_to_GPS_Time = 1;
    fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');

    %% Calculate GPSfromROS_Time in GPS sensors --> GPSfromROS_Time_exists_in_all_GPS_sensors
    % Fills in an estimate of GPS time from ROS time in GPS sensors
    %    ### ISSUES with this:
    %    * The ROS time might not match the GPS time. If there are errors
    %    in the GPS sensors, the same errors are likely in other sensors.
    %    ### DETECTION:
    %    * Make sure the field exists
    %    ### FIXES:
    %    * Calculate GPS time from ROS time via function call

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: GPSfromROS_Time_exists_in_all_GPS_sensors  \n');

    [timeFlags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(nextDataStructure,'GPSfromROS_Time',timeFlags,'all','GPS',fid);

    if (1==flag_keep_checking) && (0==timeFlags.GPSfromROS_Time_exists_in_all_GPS_sensors)
        % Fix the data
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found GPS sensor without GPSfromROS_Time, in sensor: %s \n\tAttempting a fix... ', offending_sensor));

        % Used to create test data
        if 1==0
            % fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
            % dataStructure = nextDataStructure;
            % save(fullExampleFilePath,'dataStructure');
        end

        sensors_to_check = 'GPS';
        figNum = [];

        nextDataStructure = fcn_TimeClean_fillGPSTimeFromROSTime(mean_fit, filtered_median_errors, nextDataStructure, (sensors_to_check), (fid), (figNum));

        % Did it work?
        [timeFlags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(nextDataStructure,'GPSfromROS_Time',timeFlags,'all','GPS',fid);

        if (1==timeFlags.GPSfromROS_Time_exists_in_all_GPS_sensors)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1;
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: Found GPS sensor without GPSfromROS_Time, in sensor %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
    end

    % %% Check if ROS_Time_rounds_correctly_to_Trigger_Time_in_GPS_sensors
    % % Check that the ROS Time, when rounded to the nearest sampling interval,
    % % matches the Trigger time in all GPS sensors
    % %    ### ISSUES with this:
    % %    * The data on some sensors are triggered, inlcuding the GPS sensors
    % %    which are self-triggered
    % %    * If the rounding does not work, this indicates a problem in the ROS
    % %    master
    % %    ### DETECTION:
    % %    * Round the ROS Time and compare to the Trigger_Times
    % %    ### FIXES:
    % %    * Remove and interpolate time field if not strictly increasing
    % 
    % fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: ROS_Time_rounds_correctly_to_Trigger_Time_in_GPS_sensors  \n');
    % 
    % 
    % [timeFlags,offending_sensor,~] = fcn_TimeClean_checkTimeRoundsCorrectly(nextDataStructure, 'ROS_Time',timeFlags,'Trigger_Time','GPS',fid); 
    % 
    % if 0==timeFlags.ROS_Time_rounds_correctly_to_Trigger_Time_in_GPS_sensors
    %     fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL - ROS time does not round to Trigger Time in sensor: %s\n', offending_sensor));
    %     % warning('on','backtrace');
    %     % warning('ROS_Time needs to be rounded to Trigger_Time in all GPS sensors')
    %     % return
    % else
    %     fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
    % end

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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: GPSfromROS_Time_sample_counts_match_centiSeconds_in_GPS_sensors  \n');

    verificationTypeFlag = 2;  % Check length of GPSfromROS_Time against centiSeconds
    [timeFlags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(nextDataStructure,'GPSfromROS_Time', verificationTypeFlag, timeFlags, 'GPS',fid, plotFlags.figNum_checkTimeSamplingConsistency_GPSTime);


    if (1==flag_keep_checking) && (0==timeFlags.GPSfromROS_Time_sample_counts_match_centiSeconds_in_GPS_sensors)
        fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL - GPSfromROS_Time sample counts does not match centiSeconds in sensor: %s\n', offending_sensor));
        % Used to create test data
        if 1==0
            fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
            dataStructure = nextDataStructure;
            save(fullExampleFilePath,'dataStructure');
        end

        error('This is not programmed yet');
        % nextDataStructure = fcn_TimeClean_recalculateTriggerTimes(nextDataStructure,'gps',fid);
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
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
    %    * Resample the sensor?

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: GPSfromROS_Time_sampling_matches_centiSeconds_in_GPS_sensors  \n');

    verificationTypeFlag = 1;

    
    if 1==0
        dataStructure = nextDataStructure;
        field_name = 'GPSfromROS_Time';
        flags = timeFlags;
        sensors_to_check = 'GPS';
        figNum = plotFlags.figNum_checkTimeSamplingConsistency_GPSTime;
        save('checkTimeSamplingConsistency_CASE90001.mat','dataStructure','field_name','verificationTypeFlag','flags','sensors_to_check','fid','figNum');
        error('bug caught and saved. Exiting');
    end

    [timeFlags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(nextDataStructure,'GPSfromROS_Time', verificationTypeFlag, timeFlags, 'GPS',fid, plotFlags.figNum_checkTimeSamplingConsistency_GPSTime);



    if (1==flag_keep_checking) && (0==timeFlags.GPSfromROS_Time_sampling_matches_centiSeconds_in_GPS_sensors)
        % Fix the data
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found GPS sensor where GPSfromROS_Time sampling does not match centiSeconds, in sensor: %s \n\tAttempting a fix... ', offending_sensor));

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


        % Did it work?
        [timeFlags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(nextDataStructure,'GPSfromROS_Time', verificationTypeFlag, timeFlags, 'GPS',fid, plotFlags.figNum_checkTimeSamplingConsistency_GPSTime);

        if (1==timeFlags.GPSfromROS_Time_sampling_matches_centiSeconds_in_GPS_sensors)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1;
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: Still found GPS sensor where GPSfromROS_Time sampling does not match centiSeconds, in sensor %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
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

    %% ERROR if centiSeconds_exists_in_all_sensors
    %    ### ISSUES with this:
    %    * This field defines the expected sample rate for each sensor
    %    ### DETECTION:
    %    * Examine if centiSeconds fields exist on all sensors
    %    ### FIXES:
    %    * Manually fix, or
    %    * Remove this sensor

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: centiSeconds_exists_in_all_sensors  \n');

    [timeFlags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(nextDataStructure,'centiSeconds',timeFlags,'all',[],fid);

    if (1==flag_keep_checking) && (0==timeFlags.centiSeconds_exists_in_all_sensors)
        fcn_INTERNAL_printChecking(fid,'*red','FAIL\n');
        disp(nextDataStructure.(offending_sensor))
        warning('on','backtrace');
        warning('Fundamental error on GPS_time: a GPS sensor is missing centiSeconds!? Sensor name: %s', offending_sensor);
        error('Catastrophic data error detected: the following GPS sensor is missing centiSeconds: %s.',offending_sensor);
    end

    fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');

    %% FIX if ROS_Time_has_no_repeats_in_nonGPS_sensors
    %    ### ISSUES with this:
    %    * If there are any repeated time values, the interpolation in
    %    later steps will break
    %    ### DETECTION:
    %    * Examine if time values are unique
    %    ### FIXES:
    %    * Remove repeats

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: ROS_Time_has_no_repeats_in_nonGPS_sensors  \n');

    % FORMAT: [flags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(dataStructure, field_name, (flags), (sensors_to_check), (fid), (figNum))
    [timeFlags, offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(nextDataStructure,'ROS_Time',timeFlags, 'nonGPS', (fid),(-1));


    if (1==flag_keep_checking) && (0==timeFlags.ROS_Time_has_no_repeats_in_nonGPS_sensors)
        % Fix the data
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found sensor where ROS_Time has repeats or NaN values, in sensor: %s \n\tAttempting a fix... ', offending_sensor));

        % Fix the data
        field_name = 'ROS_Time';
        [~,sensorNames] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(nextDataStructure, field_name, []);

        % Don't fix GPS sensors - they are better than ROS
        sensorsNotGPS = sensorNames(~contains(sensorNames,'GPS'));

        if 1==0
            fullExampleFilePath = fullfile(cd,'Data','ExampleData_trimRepeatsFromField_Case20001.mat');
            dataStructure = nextDataStructure;
            save(fullExampleFilePath,'dataStructure','field_name','sensors_to_check');
        end

        for ith_sensor = 1:length(sensorsNotGPS)
            thisSensor = sensorsNotGPS{ith_sensor};

            % FORMAT:
            %      trimmed_dataStructure = fcn_INTERNAL_trimRepeatsFromField(...
            %         dataStructure, (fid), (field_name), (sensors_to_check))
            nextDataStructure = fcn_TimeClean_trimRepeatsFromField(nextDataStructure,fid, field_name, thisSensor);
        end

        % FORMAT: [flags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(dataStructure, field_name, (flags), (sensors_to_check), (fid), (figNum))
        [timeFlags, offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(nextDataStructure,'ROS_Time',timeFlags, 'nonGPS', (fid),(-1));

        if (1==timeFlags.ROS_Time_has_no_repeats_in_nonGPS_sensors)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1;
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: still Found sensor where ROS_Time has repeats or NaN values, in sensor %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: ROS_Time_strictly_ascends_in_all_sensors  \n');

    [timeFlags,offending_sensor,~] = fcn_TimeClean_checkDataStrictlyIncreasing(nextDataStructure, 'ROS_Time', (timeFlags), ([]), (fid), ([]));

    if (1==flag_keep_checking) && (0==timeFlags.ROS_Time_strictly_ascends_in_all_sensors)
        fcn_INTERNAL_printChecking(fid,'*red','FAIL\n');
        warning('on','backtrace');
        warning('Fundamental error on ROS_time: it is not counting up!? Sensor name: %s', offending_sensor);
        error('ROS time is not strictly ascending.');
        flag_keep_checking = 0;
    end

    fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');

    %% Calculate GPSfromROS_Time in all sensors --> GPSfromROS_Time_exists_in_all_sensors
    % Fills in an estimate of GPS time from ROS time in all sensors
    %    ### ISSUES with this:
    %    * The ROS time might not match the GPS time. If there are errors
    %    in the GPS sensors, the same errors are likely in other sensors.
    %    ### DETECTION:
    %    * Make sure the field exists
    %    ### FIXES:
    %    * Calculate GPS time from ROS time via function call

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: GPSfromROS_Time_exists_in_all_sensors  \n');

    [timeFlags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(nextDataStructure,'GPSfromROS_Time',timeFlags,'all',[],fid);

    if (1==flag_keep_checking) && (0==timeFlags.GPSfromROS_Time_exists_in_all_sensors)
        % Tell user what is happening
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found sensor where GPSfromROS_Time does not exist, in sensor: %s \n\tAttempting a fix... ', offending_sensor));

        % Fix the data
        % Used to create test data
        if 1==0
            % fullExampleFilePath = fullfile(cd,'Data','ExampleData_fitROSTime2GPSTime.mat');
            % dataStructure = nextDataStructure;
            % save(fullExampleFilePath,'dataStructure');
        end

        sensors_to_check = [];
        figNum = [];

        nextDataStructure = fcn_TimeClean_fillGPSTimeFromROSTime(mean_fit, filtered_median_errors, nextDataStructure, (sensors_to_check), (fid), (figNum));

        % Did the fix work?

        [timeFlags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(nextDataStructure,'GPSfromROS_Time',timeFlags,'all',[],fid);

        if (1==timeFlags.GPSfromROS_Time_exists_in_all_sensors)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1;
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: still found sensor where GPSfromROS_Time does not exist, in sensor %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: GPSfromROS_Time_has_consistent_start_end_across_all_sensors  \n');

    [timeFlags, offending_sensor, ~] = fcn_TimeClean_checkConsistencyOfStartEnd(nextDataStructure, 'GPSfromROS_Time', (timeFlags), ('GPS'), ('_across_all_sensors'), (.05), (fid), ([]));

    if (1==flag_keep_checking) && (0==timeFlags.GPSfromROS_Time_has_consistent_start_end_across_all_sensors)
        % Tell user what is happening
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found sensor where GPSfromROS_Time does not have consistent start/end, in sensor: %s \n\tAttempting a fix... ', offending_sensor));

        % Fix the data
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

        % For debugging
        if 1==0
            % [startTimes, ~] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(nextDataStructure, 'GPSfromROS_Time', 'GPS','first_row');
            % startValues = cell2mat(startTimes');
            % readableValues = startValues - startValues(1);
            % 
            % [startGPSTimes, ~] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(nextDataStructure, 'GPS_Time', 'GPS','first_row');
            % startValuesGPS = cell2mat(startGPSTimes');
            % readableValuesGPSstart = startValuesGPS - startValuesGPS(1);
            % 
            % [finishTimes, ~] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(nextDataStructure, 'GPSfromROS_Time', 'GPS','last_row');
            % finishValues = cell2mat(finishTimes');
            % readableValuesFinish = finishValues - finishValues(1);
            % 
            % [finishGPSTimes, ~] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(nextDataStructure, 'GPS_Time', 'GPS','last_row');
            % finishValuesGPS = cell2mat(finishGPSTimes');
            % readableValuesGPSfinish = finishValuesGPS - finishValuesGPS(1);
        end

        warning('This section not complete');

        % Did the fix work?
        [timeFlags, offending_sensor, ~] = fcn_TimeClean_checkConsistencyOfStartEnd(nextDataStructure, 'GPSfromROS_Time', (timeFlags), ('GPS'), ('_across_all_sensors'), (.005), (fid), ([]));

        if (1==timeFlags.GPSfromROS_Time_has_consistent_start_end_across_all_sensors)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1;
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: still found sensor where GPSfromROS_Time does not have consistent start/end, in sensor %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
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

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: Trigger_Time_exists_in_all_sensors  \n');

    [timeFlags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(nextDataStructure,'Trigger_Time',timeFlags,'all',[],fid);

    if (1==flag_keep_checking) && (0==timeFlags.Trigger_Time_exists_in_all_sensors)
        % Tell user what is happening
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found sensor where Trigger_Time does not exist, in sensor: %s \n\tAttempting a fix... ', offending_sensor));

        % Fix the data
        % Used to create test data
        if 1==1
            fullExampleFilePath = fullfile(cd,'Data','ExampleData_recalculateTriggerTimes.mat');
            dataStructure = nextDataStructure;
            save(fullExampleFilePath,'dataStructure');
        end

        nextDataStructure = fcn_TimeClean_recalculateTriggerTimes(nextDataStructure,[],fid);
  
        % Did the fix work?
        [timeFlags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(nextDataStructure,'Trigger_Time',timeFlags,'all',[],fid);

        if (1==timeFlags.Trigger_Time_exists_in_all_sensors)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1;
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: still found sensor where Trigger_Time does not exist, in sensor %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
    end


    %% Check if ROS_Time_has_same_length_as_Trigger_Time_in_all_sensors
    %    ### ISSUES with this:
    %    * This Trigger_Time is used to assign data collection timings for all
    %    non-GPS-triggered sensors
    %    * All the sensor data should have same length as ROS_Time
    %    * This flag checks if all sensor data is aligned to this time
    %    ### DETECTION:
    %    * Examine if ROS_Time length matches Trigger_Time length
    %    ### FIXES:
    %    * Find index interval, in GPSfromROS_Time, that is within
    %    Trigger_Time interval. Assign these indices to sensor data.

    fcn_INTERNAL_printChecking(fid,'*blue','Checking flag: ROS_Time_has_same_length_as_Trigger_Time_in_all_sensors  \n');

    [timeFlags,offending_sensor,~]  = fcn_TimeClean_checkFieldCountMatchesTimeCount(nextDataStructure,'ROS_Time',timeFlags,'Trigger_Time','',fid);


    if (1==flag_keep_checking) && (0==timeFlags.ROS_Time_has_same_length_as_Trigger_Time_in_all_sensors)
        % Tell user what is happening
        fcn_INTERNAL_printChecking(fid,'*cyan','POSSIBLE ERROR\n');
        fcn_INTERNAL_printChecking(fid,'*cyan', sprintf('Found sensors where Trigger_Time does not match ROS_Time in sensor: %s \n\tAttempting a fix... ', offending_sensor));

        % Fix the data
        % Used to create test data
        if 1==0
            fullExampleFilePath = fullfile(cd,'Data','ExampleData_fcn_TimeClean_fixAlignSensorsToTime.mat');
            dataStructure = nextDataStructure;
            save(fullExampleFilePath,'dataStructure');
        end

        nextDataStructure = fcn_TimeClean_fixAlignSensorsToTime(nextDataStructure,[],fid);
  
        % Did the fix work?
        [timeFlags,offending_sensor,~]  = fcn_TimeClean_checkFieldCountMatchesTimeCount(nextDataStructure,'ROS_Time',timeFlags,'Trigger_Time','',fid);

        if (1==timeFlags.ROS_Time_has_same_length_as_Trigger_Time_in_all_sensors)
            fcn_INTERNAL_printChecking(fid,'*green','FIXED.\n');
            flag_keep_checking = 1; %#ok<NASGU>
        else
            fcn_INTERNAL_printChecking(fid,'*red',sprintf('FAIL: still found sensor where Trigger_Time has different length than ROS_Time, in %s\n', offending_sensor));
            error('COULD NOT BE FIXED. EXITING.\n');
        end
    else
        fcn_INTERNAL_printChecking(fid,'*green','\tPASSED\n');
    end
    %%



    currentDataStructure = nextDataStructure;
    currentDataStructure.Identifiers = Identifiers_Hold;

    % Check all the time_flags, so we can exit!
    flag_stay_in_main_loop = fcn_INTERNAL_checkFlagsForExit(timeFlags);

    % Have we done too many loops?
    if main_data_clean_loop_iteration_number>N_max_loops
        flag_stay_in_main_loop = 0;
    end

    % Are flags same as they were?
    flagsWereChanged = fcn_INTERNAL_compareOldAndNewFlags(oldTimeFlags, timeFlags);
    if 0==flagsWereChanged
        flag_stay_in_main_loop = 0; %#ok<NASGU>
        warning('Unable to complete time cleaning - flags were not changed.');
        cleanDataStruct = [];
        subPathStrings = [];
        return;
    end

end

main_data_clean_loop_iteration_number = main_data_clean_loop_iteration_number+1;
fprintf(1,'%.0f \n', main_data_clean_loop_iteration_number);
debugging_data_structure_sequence{main_data_clean_loop_iteration_number} = currentDataStructure; %#ok<NASGU>
cleanDataStruct = currentDataStructure;
subPathStrings = '';

%%
fprintf(fid,'Cleaning completed. Num of iterations needed: %.0f (out of %.0f allowed)\n', main_data_clean_loop_iteration_number, N_max_loops);
fcn_INTERNAL_reportFlagStatus(timeFlags,'TIMING FLAGS', fid);

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

    % if fid
    %     fprintf(fid,'\nBEGINNING PLOTTING: \n');
    % end

    %
    % %% Save plotted images?
    % if ~isempty(plotFlags.figNum_checkTimeSamplingConsistency_GPSTime)
    %     % Save the image to file?
    %     if 1==saveFlags.flag_saveImages
    %         figure(plotFlags.figNum_checkTimeSamplingConsistency_GPSTime);
    %         fcn_INTERNAL_saveImages(cat(2,'cleanTime_GPS_',Identifiers.WorkZoneScenario), saveFlags);
    %     end
    %
    % end
    %
    % if  ~isempty(plotFlags.figNum_checkTimeSamplingConsistency_ROSTime)
    %     % Save the image to file?
    %     if 1==saveFlags.flag_saveImages
    %         figure(plotFlags.figNum_checkTimeSamplingConsistency_ROSTime);
    %         fcn_INTERNAL_saveImages(cat(2,'cleanTime_ROS_',Identifiers.WorkZoneScenario), saveFlags);
    %     end
    %
    % end
    %
    %
    %
    % % %% Save mat file?
    % % if ~isempty(plotFlags.figNum_checkTimeSamplingConsistency_ROSTime)
    % %     % Save the mat file?
    % %     if 1 == saveFlags.flag_saveMatFile
    % %         fcn_INTERNAL_saveMATfile(rawDataCellArray{ith_rawData}, char(bagName_clean), saveFlags);
    % %     end
    % % end



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
function fcn_INTERNAL_reportFlagStatus(flagStructure,printTitle, fid)
fprintf(fid,'\n%s\n',printTitle);
fieldsToprint = fieldnames(flagStructure);
NcharactersField = 50;
for ith_field = 1:length(fieldsToprint)
    thisField = fieldsToprint{ith_field};
    formattedHeaderString  = fcn_DebugTools_debugPrintStringToNCharacters(thisField,NcharactersField);
    fprintf(fid,'%s\t',formattedHeaderString);
    fieldValue = flagStructure.(thisField);
    if 1==fieldValue
        fieldString = 'yes';
    else
        fieldString = 'no';
    end
    fprintf(fid,'%s\n',fieldString);
end
fprintf(fid,'\n');
end % Ends fcn_INTERNAL_reportFlagStatus


%% fcn_INTERNAL_saveImages
function fcn_INTERNAL_saveImages(imageName, saveFlags) %#ok<DEFNU>

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
function  fcn_INTERNAL_saveMATfile(rawData, MATfileName, saveFlags) %#ok<DEFNU>

MAT_fname = cat(2,MATfileName,'.mat');
MAT_fullPath = fullfile(saveFlags.flag_saveMatFile_directory,MAT_fname);
if 2~=exist(MAT_fullPath,'file') || 1==saveFlags.flag_forceMATfileOverwrite
    save(MAT_fullPath,'rawData');
end

end % Ends fcn_INTERNAL_saveMATfile


%% fcn_INTERNAL_compareOldAndNewFlags
function flagsWereChanged = fcn_INTERNAL_compareOldAndNewFlags(oldTimeFlagsStruct, newTimeFlagsStruct)

% Initialize the output variable
flagsWereChanged = 0;

% Pull the fields
oldFields = fieldnames(oldTimeFlagsStruct);
newFields = fieldnames(newTimeFlagsStruct);

% Count the fields
if length(oldFields) ~= length(newFields)
    flagsWereChanged = 1;
else

    % Check field by field that same names exist
    for ith_field = 1:length(oldFields)
        thisOldField = oldFields{ith_field};
        if ~any(strcmp(newFields,thisOldField))
            flagsWereChanged = 1;
        end
    end

    % Check that values in fields match exactly
    if 0==flagsWereChanged
        % Check values one by one
        for ith_field = 1:length(oldFields)
            thisField = oldFields{ith_field};
            if oldTimeFlagsStruct.(thisField) ~= newTimeFlagsStruct.(thisField)
                flagsWereChanged = 1;
            end
        end
    end
end


end % Ends fcn_INTERNAL_compareOldAndNewFlags

%% fcn_INTERNAL_checkIfROSTimeMisScaled
function [flags,offending_sensor,return_flag] = fcn_INTERNAL_checkIfROSTimeMisScaled(fid, dataStructure, flags)
% Checks to see if the ROS_Time fields are wrongly scaled

% Initialize offending_sensor
offending_sensor = '';

% Produce a list of all the sensors (each is a field in the structure)
[~,sensor_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(dataStructure, 'GPS_Time','GPS');

if 0~=fid
    fprintf(fid,'Checking if ROS time is measured in seconds, not nanoseconds, across GPS sensors:\n');
end

flags_data_good = ones(length(sensor_names),1);

for i_data = 1:length(sensor_names)
    % Grab the sensor subfield name
    sensor_name = sensor_names{i_data};
    sensor_data = dataStructure.(sensor_name);

    if 0~=fid
        fprintf(fid,'\t Checking sensor %d of %d: %s\n',i_data,length(sensor_names),sensor_name);
    end

    GPS_Time = sensor_data.GPS_Time;
    ROS_Time = sensor_data.ROS_Time;

    length_to_use = length(GPS_Time(:,1));
    if length(GPS_Time(:,1)) ~= length(ROS_Time(:,1))
        warning('on','backtrace');
        warning('Dissimilar ROS and GPS time lengths detected. This indicates a major sensor error.');
        if length(GPS_Time(:,1))>length(ROS_Time(:,1))
            length_to_use = length(ROS_Time(:,1));
        end
    end
    mean_ratio = mean(ROS_Time(1:length_to_use,1)./GPS_Time(1:length_to_use,1));

    if (0.95*1E9)<mean_ratio && mean_ratio<(1.05*1E9)
        flags_data_good(i_data,1) = 0;
        offending_sensor = sensor_name;
    elseif 0.95 > mean_ratio || mean_ratio>1.05
        warning('on','backtrace');
        warning('Bad ratio detected.')
        error('Strange ratio detected between ROS Time and GPS Time');
    end
end

if all(flags_data_good==0)
    flags.ROS_Time_scaled_correctly_as_seconds = 0;
elseif any(flags_data_good==0)
    warning('on','backtrace');
    warning('Some GPS sensors appear to be scaled incorrectly where ROS_Time is not in seconds. This indicates a data loading error.');
    flags.ROS_Time_scaled_correctly_as_seconds = 0;
else
    flags.ROS_Time_scaled_correctly_as_seconds = 1;
end

if 0==flags.ROS_Time_scaled_correctly_as_seconds
    return_flag = 1; % Indicate that the return was forced
    return
else
    return_flag = 0; % Indicate that the return was NOT forced
end

% If get here, there are NO offending sensors!
offending_sensor = '';


end % Ends fcn_INTERNAL_checkIfROSTimeMisScaled


function fcn_INTERNAL_printChecking(fid,colorString,varargin)
if 1==fid
    fcn_DebugTools_cprintf(colorString,varargin{1});
else
    fprintf(fid,varargin{1});
end
end