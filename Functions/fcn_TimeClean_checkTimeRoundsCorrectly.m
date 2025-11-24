%% fcn_TimeClean_checkROSTimeRoundsCorrectly
function [flags,offending_sensor,return_flag] = fcn_TimeClean_checkTimeRoundsCorrectly(dataStructure, field_name, varargin)
% fcn_TimeClean_checkTimeRoundsCorrectly
% Given a data structure and the field name, checks every sensor to see if
% the field, when rounded to the centiSecond value of the sensor, matches
% the given time field. This is most commonly used to check whether the
% ROS_Time, when rounded, matches the Trigger_Time
%
% FORMAT:
%
%      [flags,offending_sensor] = fcn_TimeClean_checkTimeRoundsCorrectly(...
%          dataStructure, field_name,...
%          (flags), (time_field), (sensors_to_check), (fid))
%
% INPUTS:
%
%      dataStructure: a data structure to be analyzed
%
%      field_name: the field to be tested against the time field
%
%      (OPTIONAL INPUTS)
%
%      flags: If a structure is entered, it will append the flag result
%      into the structure to allow a pass-through of flags structure
%
%      time_field: the time field used for coparison. If empty, the default
%      is 'Trigger_Time'.
%
%      sensors_to_check: a string listing the sensors to check. For
%      example, 'GPS' will check every sensor in the dataStructure whose
%      name contains 'GPS'. Default is empty, which checks all sensors.
%
%      fid: a file ID to print results of analysis. If not entered, no
%      output is given (FID = 0). Set fid to 1 for printing to console.
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
%     See the script: script_test_fcn_TimeClean_checkTimeRoundsCorrectly
%     for a full test suite.
%
% This function was written on 2023_07_02 by S. Brennan
% Questions or comments? sbrennan@psu.edu 

% REVISION HISTORY:
%     
% 2023_07_02 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally 
% 
% 2024_09_27 by Sean Brennan, sbrennan@psu.edu
% - Updated top comments
% - Added debug flag area
% - Fixed fid printing error
% - Added figNum input, fixed the plot flag
% - Fixed warning and errors

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)


%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the figNum variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
flag_max_speed = 0;
if (nargin==6 && isequal(varargin{end},-1))
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
        narginchk(2,6);
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
time_field = 'Trigger_Time';
if 4 <= nargin
    temp = varargin{2};
    if ~isempty(temp)
        time_field = temp;
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
% Check for user input?
if (0 == flag_max_speed)
    if 6 <= nargin
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

% Set up flags based on input conditions
% Should all sensors be checked?
if isempty(sensors_to_check)
    flag_check_all_sensors = 1;    
else
    flag_check_all_sensors = 0;
end

if flag_check_all_sensors
    flag_name = sprintf('%s_rounds_correctly_to_%s_in_all_sensors',field_name,time_field);
else
    flag_name = sprintf('%s_rounds_correctly_to_%s_in_%s_sensors',field_name,time_field,sensors_to_check);
end


% Initialize offending_sensor
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

if 0<fid
    if isempty(sensors_to_check)
        temp_sensors_to_check = 'all';
    else
        temp_sensors_to_check = sensors_to_check;
    end
    fprintf(fid,'Checking that %s would round correctly to %s in %s sensors:\n',field_name, time_field,temp_sensors_to_check);
end

for i_data = 1:length(sensor_names)
    % Grab the sensor subfield name
    sensor_name = sensor_names{i_data};
    sensor_data = dataStructure.(sensor_name);
    
    if 0~=fid
        fprintf(fid,'\t Checking sensor %d of %d: %s\n',i_data,length(sensor_names),sensor_name);
    end
    
    % Set initial flag value
    flags_data_rounds_correctly = 1;
    
    % Find multiplier that converts seconds into centiseconds. Usually,
    % this is 100. But if centiSeconds is a weird number, like 7, it can
    % introduce errors. In the case 
    multiplier = round(100/sensor_data.centiSeconds);
    
    % Round ROS_Time   
    RawTime = (sensor_data.(field_name)-sensor_data.(field_name)(1,1));
    Rounded_Field_Time_samples_centiSeconds   = round(RawTime*multiplier)*sensor_data.centiSeconds;
       
    % Round the Trigger_Time
    Rounded_Trigger_Time_samples_centiSeconds   = round((sensor_data.(time_field)-sensor_data.(time_field)(1,1))*multiplier)*sensor_data.centiSeconds;
    
    % Check if they are the same
    if ~isequal(Rounded_Field_Time_samples_centiSeconds,Rounded_Trigger_Time_samples_centiSeconds)
        flags_data_rounds_correctly = 0;
    end
        
    if 0==return_flag && ~flags_data_rounds_correctly
        return_flag = 1; % Indicate that the return was forced
    end

    if 0==flags_data_rounds_correctly
        if isempty(offending_sensor)
            offending_sensor = sensor_name;
        else
            offending_sensor = cat(2,offending_sensor,' ',sensor_name); % Save the name of the sensor
        end
        return_flag = 1; % Indicate that the return was forced 

        % Show what went wrong?
        if 0~=fid
            maxOff = max(abs(Rounded_Field_Time_samples_centiSeconds-Rounded_Trigger_Time_samples_centiSeconds));
            all_bad = find(Rounded_Field_Time_samples_centiSeconds~=Rounded_Trigger_Time_samples_centiSeconds);
            Nsamples = length(Rounded_Field_Time_samples_centiSeconds);
            bad_index = all_bad(1);
            start_print = max(bad_index-5,1);
            end_print = min(bad_index+5,length(Rounded_Field_Time_samples_centiSeconds(:,1)));
            temp = [RawTime Rounded_Field_Time_samples_centiSeconds Rounded_Trigger_Time_samples_centiSeconds];
            fprintf(1,'\t\tFAILURES FOUND:  total failures --> %.0d of %.0d (%.0f percent)\n',length(all_bad),Nsamples,length(all_bad)/Nsamples*100);
            fprintf(1,'\t\tExample of failure:\n')
            fprintf(1,'\t\t\t (Raw) \t (Field) \t (Trigger)\n')
            for ith_index = start_print:end_print
                if ith_index~=bad_index
                    fprintf(1,'\t\t\t %.4f \t %.0d \t %.0d\n',temp(ith_index,1),temp(ith_index,2),temp(ith_index,3))
                else
                    fcn_DebugTools_cprintf('Red','\t\t\t %.4f \t %.0d \t %.0d\n',temp(ith_index,1),temp(ith_index,2),temp(ith_index,3))
                end
            end
            fprintf(1,'\t\tMaximum offset:  %.0d centiseconds\n',maxOff);
            
        end
    end    
   
end

if 0==return_flag
    flags.(flag_name) = 1;
else
    flags.(flag_name) = 0;
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

end % Ends fcn_TimeClean_checkTimeRoundsCorrectly


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

