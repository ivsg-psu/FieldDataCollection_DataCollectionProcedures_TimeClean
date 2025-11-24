function corrected_dataStructure = fcn_TimeClean_correctTimeZoneErrorsInGPSTime(dataStructure,varargin)

% fcn_TimeClean_correctTimeZoneErrorsInGPSTime
% Finds sensors that may have wrong time zone on GPS time, and corrects
% these to common UTC time.
%
% The method this is done is to:
% 1. Pull out the GPS_Time field from all GPS-tagged sensors
% 2. Find the start values for each. 
% 3. Pull out the ROS_Time field from all GPS-tagged sensors
% 4. Find the start values for each. 
% 5. Check if these are the same. If they are, the time zone is wrong. For
% time zones that are wrong, fix the GPS_Time field.
%
% FORMAT:
%
%      corrected_dataStructure = fcn_TimeClean_correctTimeZoneErrorsInGPSTime(dataStructure,(fid))
%
% INPUTS:
%
%      dataStructure: a data structure to be analyzed that includes the following
%      fields:
%
%      (OPTIONAL INPUTS)
%
%      fid: a file ID to print results of analysis. If not entered, the
%      console (FID = 1) is used.
%
% OUTPUTS:
%
%      corrected_dataStructure: the data structure with time zone corrected
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%
% EXAMPLES:
%
%     See the script: script_test_fcn_TimeClean_correctTimeZoneErrorsInGPSTime
%     for a full test suite.
%
% This function was written on 2023_06_29 by S. Brennan
% Questions or comments? sbrennan@psu.edu 

% REVISION HISTORY:
%     
% 2023_06_29 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally 

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)



%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the figNum variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
MAX_NARGIN = 2; % The largest Number of argument inputs to the function
flag_max_speed = 0;
if (nargin==3 && isequal(varargin{end},-1))
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

if (0 == flag_max_speed)
    if flag_check_inputs
        % Are there the right number of inputs?
        narginchk(1,MAX_NARGIN);
    end
end

% Does the user want to specify the fid?

% Check for user input
if 1 <= nargin
    temp = varargin{1};
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
% 1. Pull out the GPS_Time and ROS_Time field from all GPS-tagged sensor, and find the start values for each. 
% 2. Check if these are the same. If they are, the time zone is wrong. 
% 3. For time zones that are wrong, fix the GPS_Time field.


%% Step 1: Pull out the GPS_Time and ROS_Time field from all GPS-tagged sensors
% 1. Pull out the GPS_Time and ROS_Time field from all GPS-tagged sensor, and find the start values for each. 

% Initialize arrays storing centiSeconds, start_times, and end_times across
% all sensors
sensor_centiSeconds = [];
GPS_start_times_centiSeconds = [];
ROS_start_times_centiSeconds = [];
GPS_names = {};


% Produce a list of all the sensors (each is a field in the structure)
[~,sensor_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'GPS_Time','GPS');

if 0~=fid
    fprintf(fid,'Checking consistency of start and end times across GPS sensors:\n');
end

% Loop through the fields, searching for ones that have "GPS" in their name
for i_data = 1:length(sensor_names)
    % Grab the sensor subfield name
    sensor_name = sensor_names{i_data};
    sensor_data = dataStructure.(sensor_name);
    
    if 0~=fid
        fprintf(fid,'\t Checking sensor %d of %d: %s\n',i_data,length(sensor_names),sensor_name);
    end
    
    GPS_times_centiSeconds = round(100*sensor_data.GPS_Time/sensor_data.centiSeconds)*sensor_data.centiSeconds;
    ROS_times_centiSeconds = round(100*sensor_data.ROS_Time/sensor_data.centiSeconds)*sensor_data.centiSeconds;
    sensor_centiSeconds = [sensor_centiSeconds; sensor_data.centiSeconds]; %#ok<AGROW>
    GPS_start_times_centiSeconds = [GPS_start_times_centiSeconds; GPS_times_centiSeconds(1)]; %#ok<AGROW>
    ROS_start_times_centiSeconds = [ROS_start_times_centiSeconds; ROS_times_centiSeconds(1)]; %#ok<AGROW>
    GPS_names{end+1} = sensor_name; %#ok<AGROW>
end


%% 2. Do a vote to determine the one(s) that are wrong
% Use median to vote
time_errors = GPS_start_times_centiSeconds - median(GPS_start_times_centiSeconds);


% Initialize the result:
corrected_dataStructure = dataStructure;

% Find outliers from the vote
bad_sensor_indicies = find(abs(time_errors)>(5*100));
if ~isempty(bad_sensor_indicies)
    best_corrections = 0*bad_sensor_indicies;
    fprintf(fid,'Bad GPS_Time data found in the following sensors: \n');
    for ith_index = 1:length(bad_sensor_indicies)
        bad_index = bad_sensor_indicies(ith_index);        
        fprintf(fid,'%s\n',GPS_names{bad_index});
        fprintf(fid,'\t Start time is off by %.3f seconds\n',time_errors(bad_index)/100);
        time_correction = time_errors(bad_index)/100;
        
        % Try all the possible time zone corrections, from -24 hours to 24
        % hours ahead
        possible_corrections = (-24:24)'*60*60;
        better_times = time_correction+possible_corrections;
        [best_corrections(ith_index), min_time_zone_index] = min(abs(better_times));
        fprintf(fid,'\t It appears that the best correction is to shift time by: %d seconds. \n',possible_corrections(min_time_zone_index));
        fprintf(fid,'\t With corrections added, the time becomes: %.3f \n',best_corrections(ith_index));
        
        if abs(best_corrections(ith_index))>5
            error('Even after correction, the time error is too large - exiting\n');
        else
            corrected_dataStructure.(GPS_names{bad_index}).GPS_Time = ...
                corrected_dataStructure.(GPS_names{bad_index}).GPS_Time+possible_corrections(min_time_zone_index);
        end
    end
end
fprintf(fid,'Corrections to GPS_Time offsets are complete.\n');

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

if  fid
    fprintf(fid,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
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

