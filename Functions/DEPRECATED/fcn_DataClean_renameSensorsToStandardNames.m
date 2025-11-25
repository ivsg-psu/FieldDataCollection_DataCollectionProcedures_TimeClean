function updated_dataStructure = fcn_DataClean_renameSensorsToStandardNames(dataStructure,varargin)

warning('on','backtrace');
warning(['fcn_DataClean_renameSensorsToStandardNames is being deprecated. ' ...
    'Use fcn_TimeClean_renameSensorsToStandardNames instead.']);


% fcn_DataClean_renameSensorsToStandardNames
% renames sensor fields to standard names
%
% FORMAT:
%
%      updated_dataStructure = fcn_DataClean_renameSensorsToStandardNames(dataStructure,(fid))
%
% INPUTS:
%
%      dataStructure: a data structure to be corrected
%
%      (OPTIONAL INPUTS)
%
%      fid: a file ID to print results of analysis. If not entered, the
%      console (FID = 1) is used.
%
% OUTPUTS:
%
%      updated_dataStructure: a data structure to be analyzed that includes the following
%      fields:
%
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%
% EXAMPLES:
%
%     See the script: script_test_fcn_DataClean_renameSensorsToStandardNames
%     for a full test suite.
%
% This function was written on 2023_06_19 by S. Brennan
% Questions or comments? sbrennan@psu.edu

% Revision history:
%
% 2023_07_04: sbrennan@psu.edu
% -- wrote the code originally
% 2024_07_15: xfc5113@psu.edu
% -- update bad and good names of the fields
% 2024_09_26: sbrennan@psu.edu
% -- updated to comments
% -- added debug flag area
% -- fixed fid printing error
% -- fixed names to match example
% -- added Identifiers
% 2024_10_13: xfc5113@psu.edu
% -- added GPS_SparkFun_LeftRear_GGA and GPS_SparkFun_RightRear_GGA
% 2024_10_28: xfc5113@psu.edu
% -- added IMU_Ouster_Front

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the fig_num variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
flag_max_speed = 0;
if (nargin==2 && isequal(varargin{end},-1))
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
if 0 == flag_max_speed
    if flag_check_inputs
        % Are there the right number of inputs?
        narginchk(1,2);

    end
end

% Does the user want to specify the fid?
if (0 == flag_max_speed) && (2 <= nargin)
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
else
    fid = 0;
end

flag_do_plots = 0;

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
%% Loop through all the fields, fixing them

sensor_names = fieldnames(dataStructure); % Grab all the fields that are in dataStructure structure

%% Create a dictionary mapping bad names to good ones
correct_names = {...
'GPS_Hemisphere_TopCenter';
'DIAGNOSTIC_USDigital_RearAxle';
'DIAGNOSTIC_TrigBox_RearTop';
'NTRIP_Hotspot_Rear';
'ENCODER_USDigital_RearAxle';
'TRIGGER_TrigBox_RearTop';
'LIDAR_Sick_Rear';
'DIAGNOSTIC_Sparkfun_LeftRear';
'DIAGNOSTIC_Sparkfun_RightRear';
'DIAGNOSTIC_Sparkfun_Front';
'TRANSFORM_ROS_Rear';
'GPS_SparkFun_RightRear';
'GPS_SparkFun_LeftRear';
'GPS_SparkFun_Front';
'IMU_Adis_TopCenter';
'Velocity_Estimate_SparkFun_LeftRear';
'Velocity_Estimate_SparkFun_RightRear';
'Velocity_Estimate_SparkFun_Front';
'Identifiers';
'IMU_Ouster_Front'};
Ngood = length(correct_names);

name_pairs = {...
'Hemisphere_DGPS','GPS_Hemisphere_TopCenter';
'diagnostic_encoder','DIAGNOSTIC_USDigital_RearAxle';
'diagnostic_trigger','TRIGGER_TrigBox_RearTop';
'Raw_Encoder','ENCODER_USDigital_RearAxle';
'Diag_Encoder','DIAGNOSTIC_USDigital_RearAxle';
'Diag_Trigger','TRIGGER_TrigBox_RearTop';
'ntrip_info','NTRIP_Hotspot_Rear';
'Encoder_Raw','ENCODER_USDigital_RearAxle';
'Trigger_Raw','TRIGGER_TrigBox_RearTop';
'Raw_Trigger','TRIGGER_TrigBox_RearTop';
'RawTrigger','TRIGGER_TrigBox_RearTop';
'SickLiDAR','LIDAR_Sick_Rear';
'Lidar_Sick_Rear','LIDAR_Sick_Rear';
'sparkfun_gps_diag_rear_left', 'DIAGNOSTIC_Sparkfun_LeftRear';
'sparkfun_gps_diag_rear_right', 'DIAGNOSTIC_Sparkfun_RightRear';
'sparkfun_gps_diag_front', 'DIAGNOSTIC_Sparkfun_Front';
'transform', 'TRANSFORM_ROS_Rear';
'VelodyneLiDAR', 'LIDAR_Velodyne_Rear';
'Lidar_Velodyne_Rear','LiDAR_Velodyne_Rear';
'LiDAR_Velodyne_Rear','LiDAR_Velodyne_Rear';
'GPS_SparkFun_Front_GGA','GPS_SparkFun_Front'
'SparkFun_RearLeft_Velocity_Estimate','Velocity_Estimate_SparkFun_LeftRear';
'SparkFun_RearRight_Velocity_Estimate','Velocity_Estimate_SparkFun_RightRear';
'SparkFun_Front_Velocity_Estimate','Velocity_Estimate_SparkFun_Front';
'GPS_SparkFun_Front_GGA','GPS_SparkFun_Front';
'GPS_SparkFun_LeftRear_GGA','GPS_SparkFun_LeftRear';
'GPS_SparkFun_RightRear_GGA','GPS_SparkFun_RightRear';
'GPS_SparkFun_RearRight','GPS_SparkFun_RightRear';
'GPS_SparkFun_RearLeft','GPS_SparkFun_LeftRear';
'IMU_Adis_CenterTop','IMU_Adis_TopCenter';
'Identifiers','Identifiers';
'IMU_Ouster_Front', 'IMU_Ouster_Front'};

%% Make sure all the sensor names are in the dictionary
for ith_sensor = 1:length(sensor_names)
    sensor_name = sensor_names{ith_sensor};
    matches = strcmp(sensor_name, name_pairs);
    if ~any(matches,"all")
        warning('on','backtrace');
        warning('Unable to find string in dictionary: %s',sensor_name)
        error('Sensor name ''%s'' not found - unable to fix',sensor_name)
    end
end


%% Prepare the dictionary
[Npairs,~] = size(name_pairs);
for ith_pair = 1:Npairs    
    badNames{ith_pair} = name_pairs{ith_pair,1}; %#ok<AGROW>
    goodNames{ith_pair} = name_pairs{ith_pair,2}; %#ok<AGROW>
end
for ith_pair = 1:Ngood    
    badNames{ith_pair+Npairs} = correct_names{ith_pair};
    goodNames{ith_pair+Npairs} = correct_names{ith_pair};
end

% try
%     % IF using 2022b or later, --> BETTER: d = dictionary(badNames,goodNames);
%     dictionaryMap = dictionary(badNames,goodNames);
% catch
    dictionaryMap = containers.Map(badNames,goodNames);
% end



%% Print results so far?
if fid>0
    % Find the longest from name
    longest_from_string = 0;
    for ith_name = 1:length(sensor_names)
        if length(sensor_names{ith_name})>longest_from_string
            longest_from_string = length(sensor_names{ith_name});
        end
    end
    longest_from_string = max(longest_from_string,10);

    % Find the longest to name
    longest_to_string = 0;
    for ith_name = 1:length(sensor_names)
        if length(dictionaryMap(sensor_names{ith_name}))>longest_to_string
            longest_to_string = length(dictionaryMap(sensor_names{ith_name}));
        end
    end
    longest_to_string = max(longest_to_string,10);

    % Print results
    fprintf(fid,'\n\t Converting sensor names to standard notion:\n');
    
    % Print start time table
    row_title_string       = fcn_DebugTools_debugPrintStringToNCharacters('Sensor number:',7);
    sensor_from_string    = fcn_DebugTools_debugPrintStringToNCharacters('From:',longest_from_string);
    sensor_to_string     = fcn_DebugTools_debugPrintStringToNCharacters('To:',longest_to_string);    
    fprintf(fid,'\t \t %s \t %s \t %s \n',row_title_string, sensor_from_string,sensor_to_string);

    for ith_data = 1:length(sensor_names)
        row_data_string         = fcn_DebugTools_debugPrintStringToNCharacters(sprintf('%d:',ith_data),7);
        sensor_from_data_string      = fcn_DebugTools_debugPrintStringToNCharacters(sensor_names{ith_data},longest_from_string);
        sensor_to_data_string       = fcn_DebugTools_debugPrintStringToNCharacters(dictionaryMap(sensor_names{ith_data}),longest_to_string);
        fprintf(fid,'\t \t %s \t %s \t %s \n',row_data_string, sensor_from_data_string,sensor_to_data_string);
    end
    fprintf(fid,'\n');
end

%% Do the conversion
for ith_sensor = 1:length(sensor_names)

    sensor_name = sensor_names{ith_sensor};
    updated_dataStructure.(dictionaryMap(sensor_name)) = dataStructure.(sensor_name);
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

if  flag_do_debug
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

