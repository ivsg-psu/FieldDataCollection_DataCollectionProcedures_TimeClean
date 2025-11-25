function [cleanDataStruct, subPathStrings]  = fcn_TimeClean_cleanNaming(rawDataStruct, varargin)
% fcn_TimeClean_cleanNaming
% given a raw data structure, cleans field names to match expected
% standards for data cleaning methods
%
% FORMAT:
%
%      cleanDataStruct = fcn_TimeClean_cleanNaming(rawDataStruct, (fid), (Flags), (figNum))
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
%      figNum: a figure number to plot results. If set to -1, skips any
%      input checking or debugging, no figures will be generated, and sets
%      up code to maximize speed.
%
% OUTPUTS:
%
%      cleanDataStruct: a  data structure containing data fields filled for
%      each ROS topic, in name-cleaned form - e.g. all the field names are
%      compliant
%
%     subPathStrings: a string for each rawData load indicating the subpath
%     where the data was obtained
%
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%      fcn_DataClean_mergeSensorsByMethod
%
% EXAMPLES:
%
%     See the script: script_test_fcn_TimeClean_cleanNaming
%     for a full test suite.
%
% This function was written on 2024_11_05 by S. Brennan
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY
% 
% As: fcn_Data+Clean_cleanNaming
%
% 2024_11_05 by S. Brennan
% - Wrote the code by extracting out of the cleanData function
%
% As: fcn_TimeClean_cleanNaming
% 
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - Renamed function:
%   % * From: fcn_Data+Clean_cleanNaming
%   % * To: fcn_TimeClean_cleanNaming 
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - Deprecated function:
%   % * From: fcn_Data+Clean_checkDataNameConsistency
%   % % To: fcn_TimeClean_checkDataNameConsistency
% - Deprecated function:
%   % * From: fcn_Data+Clean_renameSensorsToStandardNames
%   % % To: fcn_TimeClean_renameSensorsToStandardNames
% - Changed in-use function name
%   % * From: fcn_Data+Clean_cleanNaming
%   % * To: fcn_TimeClean_cleanNaming

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the figNum variable input
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
        narginchk(1,4);

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


% Does user want to specify figNum?
flag_do_plots = 0;
if (0==flag_max_speed) &&  (4<=nargin)
    temp = varargin{end};
    if ~isempty(temp)
        figNum = temp; %#ok<NASGU>
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
N_max_loops = 30;

% Preallocate the data array
debugging_data_structure_sequence{N_max_loops} = struct;

main_data_clean_loop_iteration_number = 0; % The first iteration corresponds to the raw data loading
currentDataStructure = rawDataStruct;

% Grab the Indentifiers field from the rawDataStructure
Identifiers_Hold = rawDataStruct.Identifiers;

% if isfield(currentDataStructure, 'Trigger_Raw')
%     currentDataStructure = rmfield(currentDataStructure,'Trigger_Raw');
% else
%     nextDataStructure = currentDataStructure;
% end
% if isfield(currentDataStructure, 'Encoder_Raw')
%     currentDataStructure = rmfield(currentDataStructure,'Encoder_Raw');
% else
%     nextDataStructure = currentDataStructure;
% end
% if isfield(currentDataStructure, 'Diag_Encoder')
%     currentDataStructure = rmfield(currentDataStructure,'Diag_Encoder');
% else
%     nextDataStructure = currentDataStructure;
% end
% if isfield(currentDataStructure, 'Diag_Trigger')
%     currentDataStructure = rmfield(currentDataStructure,'Diag_Trigger');
% else
%     nextDataStructure = currentDataStructure;
% end

%%
while 1==flag_stay_in_main_loop   
    %% Keep data thus far
    main_data_clean_loop_iteration_number = main_data_clean_loop_iteration_number+1;
    debugging_data_structure_sequence{main_data_clean_loop_iteration_number} = currentDataStructure;

    fprintf(1,'\n\nName Cleaning Iteration #%.0d\n',main_data_clean_loop_iteration_number);

    %% Remove Identifiers, temporarily
    if isfield(currentDataStructure, 'Identifiers')
        nextDataStructure = rmfield(currentDataStructure,'Identifiers');
    else
        nextDataStructure = currentDataStructure;
    end
    
    
    %% Data cleaning processes to fix the latest error start here
    flag_keep_checking = 1; % Flag to keep checking (1), or to indicate a data correction is done and checking should stop (0)
    
    %% Name consistency checks start here
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   _   _                         _____                _     _                           _____ _               _
    %  | \ | |                       / ____|              (_)   | |                         / ____| |             | |
    %  |  \| | __ _ _ __ ___   ___  | |     ___  _ __  ___ _ ___| |_ ___ _ __   ___ _   _  | |    | |__   ___  ___| | _____
    %  | . ` |/ _` | '_ ` _ \ / _ \ | |    / _ \| '_ \/ __| / __| __/ _ \ '_ \ / __| | | | | |    | '_ \ / _ \/ __| |/ / __|
    %  | |\  | (_| | | | | | |  __/ | |___| (_) | | | \__ \ \__ \ ||  __/ | | | (__| |_| | | |____| | | |  __/ (__|   <\__ \
    %  |_| \_|\__,_|_| |_| |_|\___|  \_____\___/|_| |_|___/_|___/\__\___|_| |_|\___|\__, |  \_____|_| |_|\___|\___|_|\_\___/
    %                                                                                __/ |
    %                                                                               |___/
    % See: http://patorjk.com/software/taag/#p=display&f=Big&t=Name%20Consistency%20Checks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Check if sensors are merged where a sensor may produce multiple topics
    %    These sensors include:
    %    GPS_SparkFun_RightRear
    %    GPS_SparkFun_LeftRear
    %    GPS_SparkFun_Front
    %    ADIS
    %
    %    ### ISSUES with this:
    %    * Many sensors require several different datagrams to fully
    %    capture their outputs
    %    * The data grams are spread across different sensor datasets
    %    corresponding to each topic, but are actually one
    %    * If they are kept separate, the data are not processed correctly with
    %    the same time alignment on each sensor, resulting in data that was
    %    from the same time being spread across different times
    %    ### DETECTION:
    %    * Examine if the sensors have more than one field within the current
    %    datastructure, and if multiple fields have the same name (for example
    %    "GPS_SparkFun_Front") then they are NOT correctly merged
    %    ### FIXES:
    %    * Merge the data from the fields together
    %
    % Check if sensor_naming_standards_are_used
    %    ### ISSUES with this:
    %    * The sensors used on the mapping van follow a standard naming
    %    convention, such as:
    %    {'GPS','ENCODER','IMU','TRIGGER','NTRIP','LIDAR','TRANSFORM','DIAGNOSTIC','IDENTIFIERS'}
    %    and location in the form:
    %        TYPE_Manufacturer_Location
    %    ### DETECTION:
    %    * Examine if the sensor core names appear outside of the standard
    %    convention
    %    ### FIXES:
    %    * User must manually rename the fields.
    
    %% Check if sensors merged and name convention is followed -- Done
    
    [name_flags, ~] = fcn_TimeClean_checkDataNameConsistency(nextDataStructure,fid);
    
    fcn_INTERNAL_reportFlagStatus(name_flags,'NAMING FLAGS:');
    
    %% If NOT merged, fix these errors

    % Check GPS_SparkFun_RightRear_sensors_are_merged
    if (1==flag_keep_checking) && (0==name_flags.GPS_SparkFun_RightRear_sensors_are_merged)
        sensors_to_merge = 'GPS_SparkFun_RightRear';
        merged_sensor_name = 'GPS_SparkFun_RightRear';
        method_name = 'keep_unique';
        fid = 1;
        nextDataStructure = fcn_DataClean_mergeSensorsByMethod(nextDataStructure,sensors_to_merge,merged_sensor_name,method_name,-1);
        flag_keep_checking = 1;
        name_flags.GPS_SparkFun_RightRear_sensors_are_merged = 1;
    end
    % Check GPS_SparkFun_LeftRear_sensors_are_merged
    if (1==flag_keep_checking) && (0==name_flags.GPS_SparkFun_LeftRear_sensors_are_merged)
        sensors_to_merge = 'GPS_SparkFun_LeftRear';
        merged_sensor_name = 'GPS_SparkFun_LeftRear';
        method_name = 'keep_unique';
        fid = 1;
        nextDataStructure = fcn_DataClean_mergeSensorsByMethod(nextDataStructure,sensors_to_merge,merged_sensor_name,method_name,-1);
        flag_keep_checking = 1;
        name_flags.GPS_SparkFun_LeftRear_sensors_are_merged = 1;
    end

    % Check GPS_SparkFun_Front_sensors_are_merged
    if (1==flag_keep_checking) && (0==name_flags.GPS_SparkFun_Front_sensors_are_merged)
        sensors_to_merge = 'GPS_SparkFun_Front';
        merged_sensor_name = 'GPS_SparkFun_Front';
        method_name = 'keep_unique';
        fid = 1;
        nextDataStructure = fcn_DataClean_mergeSensorsByMethod(nextDataStructure,sensors_to_merge,merged_sensor_name,method_name,-1);
        flag_keep_checking = 1;
        name_flags.GPS_SparkFun_Front_sensors_are_merged = 1;
    end
    
    % Check ADIS_sensors_are_merged 
    if (1==flag_keep_checking) && (0==name_flags.ADIS_sensors_are_merged)
        sensors_to_merge = 'ADIS';
        merged_sensor_name = 'IMU_Adis_TopCenter';
        method_name = 'keep_unique';
        fid = 1;
        nextDataStructure = fcn_DataClean_mergeSensorsByMethod(nextDataStructure,sensors_to_merge,merged_sensor_name,method_name,-1);
        flag_keep_checking = 1;
        name_flags.ADIS_sensors_are_merged = 1;
    end
    
    % check if sensor_naming_standards_are_used. If not, fix this.
    if (1==flag_keep_checking) && (0==name_flags.sensor_naming_standards_are_used)
        nextDataStructure = fcn_TimeClean_renameSensorsToStandardNames(nextDataStructure,-1);
        flag_keep_checking = 1;
        name_flags.sensor_naming_standards_are_used = 1;
    end

    fcn_INTERNAL_reportFlagStatus(name_flags,'NAMING FLAGS AFTER FIXING:');
    


    %% Done!
    % Only way to get here is if everything above worked - can exit!
    if (1==flag_keep_checking)
        flag_stay_in_main_loop = 0; %#ok<NASGU>
    end
    
    %% Exiting conditions
    % if length(dataset)==1
    %     temp = dataset;
    %     clear dataset
    %     dataset{1} = temp;
    % end
    currentDataStructure = nextDataStructure;
    currentDataStructure.Identifiers = Identifiers_Hold;
      
    % Check if all the name_flags work, so we can exit!
    name_flag_stay_in_main_loop = fcn_INTERNAL_checkFlagsForExit(name_flags);
    if 0 == name_flag_stay_in_main_loop
        flag_stay_in_main_loop = 0;
    else
        flag_stay_in_main_loop = 1;
    end
    
    % Have we done too many loops?
    if main_data_clean_loop_iteration_number>N_max_loops
        flag_stay_in_main_loop = 0;
    end
          
end

main_data_clean_loop_iteration_number = main_data_clean_loop_iteration_number+1;
debugging_data_structure_sequence{main_data_clean_loop_iteration_number} = currentDataStructure; %#ok<NASGU>
cleanDataStruct = currentDataStructure;
subPathStrings = '';

fprintf(fid,'Name cleaning completed\n');

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
