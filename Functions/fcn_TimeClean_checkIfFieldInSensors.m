function [flags,offending_sensor,return_flag] = fcn_TimeClean_checkIfFieldInSensors(dataStructure, field_name,varargin)
% fcn_TimeClean_checkIfFieldInSensors
% Checks a given dataStructure to check, for each sensor, whether the field
% is there. If so, it sets a flag = 1 whose name is customized by the input
% settings. If not, it sets the flag = 0 and immediately exits.
%
% FORMAT:
%
%      [flags,offending_sensor] = fcn_TimeClean_checkIfFieldInSensors(...
%          dataStructure, field_name,...
%          (flags), (string_any_or_all), (sensors_to_check), (fid), (fig_num))
%
% INPUTS:
%
%      dataStructure: a data structure to be analyzed
%
%      field_name: the field to be checked, as a string
%
%      (OPTIONAL INPUTS)
%
%      flags: If a structure is entered, it will append the flag result
%      into the structure to allow a pass-through of flags structure
%
%      string_any_or_all: a string consisting of 'any' or 'all' indicating
%      whether the flag should be set if any sensor has the requested field
%      ('any'), or to check that all sensors have the requested field
%      ('all'). Default is 'all' if not specified or left empty ('');
%
%      sensors_to_check: a string listing the sensors to check. For
%      example, 'GPS' will check every sensor in the dataStructure whose
%      name contains 'GPS'. Default is empty, which checks all sensors.
%
%      fid: a file ID to print results of analysis. If not entered, no
%      output is given (FID = 0). Set fid to 1 for printing to console.
%
%      fig_num: a figure number to plot results. If set to -1, skips any
%      input checking or debugging, no figures will be generated, and sets
%      up code to maximize speed.
%
% OUTPUTS:
%
%      flags: a data structure containing subfields that define the results
%      of the verification check. The name of the flag is formatted by the
%      argument inputs. 
%
%      offending_sensor: this is the string corresponding to the sensor
%      field in the data structure that caused a flag to become zero. 
% 
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%
% EXAMPLES:
%
%     See the script: script_test_fcn_TimeClean_checkIfFieldInSensors
%     for a full test suite.
%
% This function was written on 2023_06_19 by S. Brennan
% Questions or comments? sbrennan@psu.edu 

% Revision history:
%     
% 2023_06_12: sbrennan@psu.edu
% -- wrote the code originally 
% 2023_06_24 - sbrennan@psu.edu
% -- added fcn_INTERNAL_checkIfFieldInAnySensor and test case in script
% 2023_06_30 - sbrennan@psu.edu
% -- fixed verbose mode bug
% 2023_07_03 - sbrennan@psu.edu
% -- added detailed printing
% 2024_09_10: Sean Brennan, sbrennan@psu.edu
% -- added debug modes
% -- added fig_num input for speed

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the fig_num variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
flag_max_speed = 0;
if (nargin==7 && isequal(varargin{end},-1))
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
        narginchk(2,7);
    end
end

% Does the user want to specify the flags?
flags = struct;
if 3 <= nargin
    temp = varargin{1};
    if ~isempty(temp)
        flags = temp;
    end
end

% Does the user want to specify the string_any_or_all?
string_any_or_all = 'all';
if 4 <= nargin
    temp = varargin{2};
    if ~isempty(temp)
        string_any_or_all = temp;
    end
end


% Does the user want to specify the sensors_to_check?
sensors_to_check = '';
if 5 <= nargin
    temp = varargin{3};
    if ~isempty(temp)
        sensors_to_check = temp;
    end
end


% Does the user want to specify the fid?
fid = 0;
% Check for user input
if 6 <= nargin
    temp = varargin{4};
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

% Does user want to specify fig_num?
flag_do_plots = 0;
if (0==flag_max_speed) &&  (7<=nargin)
    temp = varargin{end};
    if ~isempty(temp)
        fig_num = temp; %#ok<NASGU>
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


% Set up flags based on input conditions
if isempty(sensors_to_check)
    flag_check_all_sensors = 1;    
else
    flag_check_all_sensors = 0;
end

% Set up output flag name string
switch lower(string_any_or_all)
    case {'any'}
        if flag_check_all_sensors
            flag_name = sprintf('%s_exists_in_at_least_one_sensor',field_name);
        else
            flag_name = sprintf('%s_exists_in_at_least_one_%s_sensor',field_name,sensors_to_check);
        end
    case {'all'}
        if flag_check_all_sensors
            flag_name = sprintf('%s_exists_in_all_sensors',field_name);
        else
            flag_name = sprintf('%s_exists_in_all_%s_sensors',field_name, sensors_to_check);
        end
    otherwise
        error('Unrecognized setting on string_any_or_all when checking if fields are in sensors.');
end


% Initialize outputs of the function: offending_sensor and return flag
offending_sensor = '';
return_flag = 0;

% Produce a list of all the sensors (each is a field in the structure)
if flag_check_all_sensors
    sensor_names = fieldnames(dataStructure); % Grab all the fields that are in dataStructure structure
else
    % Produce a list of all the sensors that meet the search criteria, and grab
    % their data also
    [~,sensor_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, field_name,sensors_to_check);
end

% Tell the user what is happening?
if 0~=fid
    fprintf(fid,'Checking existence of %s data ',field_name);
    if flag_check_all_sensors
        fprintf(fid,': --> %s\n', flag_name);
    else
        fprintf(fid,'in %s %s sensors: --> %s\n', string_any_or_all, sensors_to_check, flag_name);
    end
end

% Loop through the sensor name list, checking each, and stopping
% immediately if we hit a bad case.

% Initialize all flags to 1 (default is that they are good)
any_sensor_exists_results = ones(length(sensor_names),1);
for i_data = 1:length(sensor_names)
    % Grab the sensor subfield name
    sensor_name = sensor_names{i_data};
    sensor_data = dataStructure.(sensor_name);
    
    % Tell the user what is happening?
    if 0~=fid
        fprintf(fid,'\t Checking sensor %d of %d: %s\n',i_data,length(sensor_names),sensor_name);
    end
    
    % Check the field to see if it exists, saving result in an array that
    % represents the results for each sensor
    flag_field_exists= 1;
    if ~isfield(sensor_data,field_name)
        % If the field is not there, then fails
        any_sensor_exists_results(i_data) = 0;
    elseif isempty(sensor_data.(field_name))
        % if field is empty, then fails
        any_sensor_exists_results(i_data) = 0;
    elseif all(isnan(sensor_data.(field_name)))        
        % if field only filled with nan, it fails
        any_sensor_exists_results(i_data) = 0;
    end   

end

% Check the all case
if strcmp(string_any_or_all,'all') && any(any_sensor_exists_results==0)
    % If any sensors have to have the field, then if all are nan, this
    % flag fails
    flag_field_exists = 0;
    failing_indicies = find(any_sensor_exists_results==0);
    offending_sensor = '';
    for ith_failure = 1:length(failing_indicies)
        current_index = failing_indicies(ith_failure);
        offending_sensor = cat(2,offending_sensor,sensor_names{current_index},' ');
    end
end

% Check the any case
if strcmp(string_any_or_all,'any') && all(any_sensor_exists_results==0)
    % If any sensors have to have the field, then if all are nan, this
    % flag fails
    flag_field_exists = 0;
    offending_sensor = sensor_names{1};
end

% Set the flag array and return accordingly
flags.(flag_name) = flag_field_exists;
if 0==flags.(flag_name)
    return_flag = 1; % Indicate that the return was forced
        % Show the results?
    if fid
        % Find the longest name
        longest_name_string = 0;
        for ith_name = 1:length(sensor_names)
            if length(sensor_names{ith_name})>longest_name_string
                longest_name_string = length(sensor_names{ith_name});
            end
        end
        
        % Print results
        fprintf(fid,'\n\t FAILURE TO FIND A FIELD DETECTED! \n');
        fprintf(fid,'\t Field that failed: %s\n',field_name);
        if flag_check_all_sensors
            fprintf(fid,'\t Searching in all sensors.\n');
        else
            fprintf(fid,'\t Searching in %s sensors.\n',sensors_to_check);
        end
        fprintf(fid,'\t Flag that indicates failure: %s\n',flag_name);
        
        % Print start time table
        fprintf(fid,'\t \t Summarizing results: \n');
        sensor_title_string = fcn_DebugTools_debugPrintStringToNCharacters('Sensors:',longest_name_string);
        flag_title_string = fcn_DebugTools_debugPrintStringToNCharacters('Does this field exist?:',25);
        fprintf(fid,'\t \t %s \t %s \n',sensor_title_string,flag_title_string);
        for ith_data = 1:length(sensor_names)
            sensor_name_string = fcn_DebugTools_debugPrintStringToNCharacters(sensor_names{ith_data},longest_name_string);
            sensor_flag_string = fcn_DebugTools_debugPrintStringToNCharacters(sprintf('%d',any_sensor_exists_results(ith_data,1)),25);
            fprintf(fid,'\t \t %s \t %s \n',sensor_name_string,sensor_flag_string);
        end
        fprintf(fid,'\n');
        
    end
end

% Tell the user what is happening?
if 0~=fid
    fprintf(fid,'\n\t Flag %s set to: %.0f\n\n',flag_name, flags.(flag_name));
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



