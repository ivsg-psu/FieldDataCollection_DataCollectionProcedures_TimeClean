function [flags,offending_sensor,sensors_without_Trigger_Time] = fcn_TimeClean_checkDataTimeConsistency_GPS(dataStructure, varargin)
% fcn_TimeClean_checkDataTimeConsistency_GPS
% Checks a given dataset to verify whether data meets key time consistency
% requirements, for GPS sensors. 
%
% Time consistency refers to any time fields in data with
% particular focus on sensors that utilize GPS timing, specifically UTC
% time as measured in Posix time, e.g. seconds since 00:00:00 on Jan 1st,
% 1970. The primary purpose of this consistency testing is to ensure the
% time sampling intervals (measured in hundreths of a second, or
% "centiSeconds"), the number of data measured, and the relationship
% between GPS time and ROS time (the time measured on the data recording
% computer) are all logically consistent. 
%
% The input is a structure that has as sub-fields each sensor, which in
% turn is a structure that also has key recordings each saved as
% sub-sub-fields. Many key features are tested in the data, changing
% certain flag values in a structure called "flags". 
% 
% The output is a structure 'flags' with subfield flags which are set so
% that the flag = 1 condition represents data that passes that particular
% consistency test. If any flags fail, the flag for that test is
% immediately set to zero and the offending sensor causing the failure is
% noted as a string output. The function immediately exits without checking
% any further flags.
%
% If no flag errors are detected, e.g. all flags = 1, then the
% 'offending_sensor' output is an empty string.
%
% FORMAT:
%
%      [flags,offending_sensor] = fcn_TimeClean_checkDataTimeConsistency_GPS(dataStructure, (flags), (fid), (plotFlags))
%
% INPUTS:
%
%      dataStructure: a data structure to be analyzed that includes the following
%      fields:
%
%      (OPTIONAL INPUTS)
%
%      flags: If a structure is entered, it will append the flag result
%      into the structure to allow a pass-through of flags structure
%
%      fid: a file ID to print results of analysis. If not entered, no
%      output is given (FID = 0). Set fid to 1 for printing to console.
%
%      plotFlags: a structure of figure numbers to plot results. If set to
%      -1, skips any input checking or debugging, no figures will be
%      generated, and sets up code to maximize speed. Uses the following:
%
%            plotFlags.fig_num_checkTimeSamplingConsistency_GPSTime
%
% OUTPUTS:
%
% Time inconsistencies include situations where the time vectors on data
% are fundamentally flawed, and are checked in order of flaws. 
%
% Many consistency tests later in the sequence depend on a sensor passing
% consistency tests early in the sequence. For example, the consistency
% check for inconsistent time sampling of ROS_Time on a particular sensor
% cannot be performed unless that same sensor has a recorded value for its
% sampling time in the 'centiSeconds' field.
%
% For timing data to be consistent, the following must be true, and
% correspond directly to the names of flags being set. For some tests, if
% they are not true, there are procedures to fix these errors and these are
% typically performed via other functions in the DataClean library.
%
% # GPS_Time tests include:
%                    GPS_Time_exists_in_at_least_one_GPS_sensor: 1
%                            GPS_Time_exists_in_all_GPS_sensors: 1
%                        centiSeconds_exists_in_all_GPS_sensors: 1
%                        GPS_Time_has_no_repeats_in_GPS_sensors: 1
%                      GPS_Time_strictly_ascends_in_GPS_sensors: 1
%       GPS_Time_sample_modes_match_centiSeconds_in_GPS_sensors: 1
%            GPS_Time_has_consistent_start_end_within_5_seconds: 1
%          GPS_Time_has_consistent_start_end_across_GPS_sensors: 1
%             GPS_Time_has_no_sampling_jumps_in_any_GPS_sensors: 1
% GPS_Time_has_no_missing_sample_differences_in_any_GPS_sensors: 1
%
% The above issues are explained in more detail in the following
% sub-sections of code.
% 
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%
% EXAMPLES:
%
%     See the script: script_test_fcn_TimeClean_checkDataTimeConsistency_GPS
%     for a full test suite.
%
% This function was written on 2024_09_30 by S. Brennan
% Questions or comments? sbrennan@psu.edu 

% Revision history:    
% 2024_09_30: sbrennan@psu.edu
% -- wrote the code originally by pulling out of checkDataTimeConsistency
% 2024_11_07: sbrennan@psu.edu
% -- added plotFlags instead of fig_num, to allow many different plotting
% options

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the fig_num variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
flag_max_speed = 0;
if (nargin==4 && isequal(varargin{end},-1))
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
if (0 == flag_max_speed)
    if flag_check_inputs
        % Are there the right number of inputs?
        narginchk(1,4);
    end
end

% Does the user want to specify the flags?
flags = struct; %#ok<NASGU>
if 2 <= nargin
    temp = varargin{1};
    if ~isempty(temp)
        flags = temp; %#ok<NASGU>
    end
end

% Does the user want to specify the fid?
fid = 0;
% Check for user input
if 3 <= nargin
    temp = varargin{2};
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

% Does user want to specify plotFlags?
% Set defaults
plotFlags.fig_num_checkTimeSamplingConsistency_GPSTime = [];
flag_do_plots = 0;
if (0==flag_max_speed) &&  (4<=nargin)
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

% Initialize flags
flags = struct;
sensors_without_Trigger_Time = '';
% flags.GPS_Time_exists_in_at_least_one_sensor = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _______ _                   _____                _     _                           _____ _               _        
%  |__   __(_)                 / ____|              (_)   | |                         / ____| |             | |       
%     | |   _ _ __ ___   ___  | |     ___  _ __  ___ _ ___| |_ ___ _ __   ___ _   _  | |    | |__   ___  ___| | _____ 
%     | |  | | '_ ` _ \ / _ \ | |    / _ \| '_ \/ __| / __| __/ _ \ '_ \ / __| | | | | |    | '_ \ / _ \/ __| |/ / __|
%     | |  | | | | | | |  __/ | |___| (_) | | | \__ \ \__ \ ||  __/ | | | (__| |_| | | |____| | | |  __/ (__|   <\__ \
%     |_|  |_|_| |_| |_|\___|  \_____\___/|_| |_|___/_|___/\__\___|_| |_|\___|\__, |  \_____|_| |_|\___|\___|_|\_\___/
%                                                                              __/ |                                  
%                                                                             |___/                                   
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Time%20Consistency%20Checks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% GPS_Time tests
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

%% Check if GPS_Time_exists_in_at_least_one_GPS_sensor
%    ### ISSUES with this:
%    * There is no absolute time base to use for the data
%    * The tracking of vehicle data relative to external sources is no
%    longer possible
%    ### DETECTION:
%    * Examine if GPS time fields exist on any GPS sensor
%    ### FIXES:
%    * Catastrophic error. Data collection should end.
%    * One option? Check if ROS_Time recorded, and is locked to UTC via NTP, use ROS
%    Time as stand-in
%    * Otherwise, complete failure of sensor recordings

[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(dataStructure,'GPS_Time',flags,'any','GPS',fid);

if 0==flags.GPS_Time_exists_in_at_least_one_GPS_sensor
    return
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


[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(dataStructure,'GPS_Time',flags,'all','GPS',fid);
if 0==flags.GPS_Time_exists_in_all_GPS_sensors
    return
end

%% Check if centiSeconds_exists_in_all_GPS_sensors
%    ### ISSUES with this:
%    * This field defines the expected sample rate for each sensor
%    ### DETECTION:
%    * Examine if centiSeconds fields exist on all sensors
%    ### FIXES:
%    * Manually fix, or
%    * Remove this sensor

[flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(dataStructure,'centiSeconds',flags,'all','GPS',fid);
if 0==flags.centiSeconds_exists_in_all_GPS_sensors
    return
end

%% Check if GPS_Time_has_no_repeats_in_GPS_sensors
%    ### ISSUES with this:
%    * If there are many repeated time values, the calculation of sampling
%    time in the next step produces grossly incorrect results
%    ### DETECTION:
%    * Examine if time values are unique
%    ### FIXES:
%    * Remove repeats
[flags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(dataStructure,'GPS_Time',flags, 'GPS', (fid),(-1));
if 0==flags.GPS_Time_has_no_repeats_in_GPS_sensors
    return
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

% [flags,offending_sensor,~] = fcn_INTERNAL_checkDataStrictlyI ncreasing(fid, dataStructure, flags, 'GPS_Time','GPS');
[flags,offending_sensor,~] = fcn_TimeClean_checkDataStrictlyIncreasing(dataStructure, 'GPS_Time', (flags), ('GPS'), (fid), ([]));
if 0==flags.GPS_Time_strictly_ascends_in_GPS_sensors
    return
end



%% Check if GPS_Time_sample_modes_match_centiSeconds_in_GPS_sensors
%    ### ISSUES with this:
%    * This field is used to confirm GPS sampling rates for all
%    GPS-triggered sensors
%    * These sensors are used to correct ROS timings, so if any are misisng, the
%    timing and thus positioning of vehicle data may be wrong
%    * The GPS unit may be configured wrong
%    * The GPS unit may be faililng or operating incorrectly
%    ### DETECTION:
%    * Examine if centiSeconds calculation of time interval matches GPS
%    time interval for data collection, on average
%    ### FIXES:
%    * Manually fix, or
%    * Remove this sensor

verificationTypeFlag = 0; 
[flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(dataStructure,'GPS_Time', verificationTypeFlag, flags, 'GPS',fid, plotFlags.fig_num_checkTimeSamplingConsistency_GPSTime);
if 0==flags.GPS_Time_sample_modes_match_centiSeconds_in_GPS_sensors
    return
end

%% Check if GPS_Time_has_consistent_start_end_across_GPS_sensors_within_5_seconds
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


% Check GPS_Time_has_consistent_start_end_across_GPS_sensors
[flags, offending_sensor, ~] = fcn_TimeClean_checkConsistencyOfStartEnd(dataStructure, 'GPS_Time', (flags), ('GPS'), ('_within_5_seconds'), (5.0), (fid), ([]));
if 0==flags.GPS_Time_has_consistent_start_end_within_5_seconds
    return
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


% Check GPS_Time_has_consistent_start_end_across_GPS_sensors
[flags, offending_sensor, ~] = fcn_TimeClean_checkConsistencyOfStartEnd(dataStructure, 'GPS_Time', (flags), ('GPS'), ('_across_GPS_sensors'), (.025), (fid), ([]));
if 0==flags.GPS_Time_has_consistent_start_end_across_GPS_sensors
    return
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

threshold_in_standard_deviations = 5;
custom_lower_threshold = 0.0001; % Time steps cannot be smaller than this
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForJumps(dataStructure,'GPS_Time',flags,threshold_in_standard_deviations, custom_lower_threshold,'any','GPS', fid);

if 0==flags.GPS_Time_has_no_sampling_jumps_in_any_GPS_sensors
    % warning('on','backtrace');
    % warning('There are jumps in differences of GPS time, GPS time needs to be interpolated')
    return
end

%% Check if GPS_Time_has_no_missing_sample_differences_in_any_GPS_sensors
%    ### ISSUES with this:
%    * The GPS_Time may have small missing portions which could occur if
%    the sensor pauses for a moment, then restarts
%    * If these missings are large, the data from the sensor may be corrupted
%    ### DETECTION:
%    * Examine if the differences in GPS_Time are out of ordinary by
%    looking at the standard deviations of the differences relative to the
%    mean differences
%    ### FIXES:
%    * Interpolate time field if only a small segment is missing

threshold_for_agreement = 0.0001; % Data must agree within this interval
expectedJump = []; % Forces default to centiSeconds*0.01 
string_any_or_all = 'any'; 
sensors_to_check = 'GPS'; 

% Show an error is detected
[flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(dataStructure, 'GPS_Time', (flags), (threshold_for_agreement), (expectedJump), (string_any_or_all), (sensors_to_check), (fid));
if 0==flags.GPS_Time_has_no_missing_sample_differences_in_any_GPS_sensors
    % warning('on','backtrace');
    % warning('There are missing data causing jumps in the differences of GPS time. To fix, GPS time needs to be interpolated')
    return
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




