function [flags,offending_sensor,return_flag] = fcn_TimeClean_checkIfFieldHasRepeatedValues(dataStructure, field_name, varargin)
% Checks to see if a particular sensor has any repeated values in the
% requested field
%
% FORMAT:
%
%      [flags,offending_sensor] = fcn_TimeClean_checkIfFieldHasRepeatedValues(dataStructure, field_name, (flags), (sensors_to_check), (fid), (figNum))
%
% INPUTS:
%
%      dataStructure: a data structure to be analyzed
%
%      field_name: the field to be checked
%
%      (OPTIONAL INPUTS)
%
%      flags: If a structure is entered, it will append the flag result
%      into the structure to allow a pass-through of flags structure
%
%      sensors_to_check: a string listing the sensors to check. For
%      example, 'GPS' will check every sensor in the dataStructure whose
%      name contains 'GPS'. Default is empty, which checks all sensors.
%
%      fid: a file ID to print results of analysis. If not entered, no
%      output is given (FID = 0). Set fid to 1 for printing to console.
%
%      figNum: a figure number to plot results. If set to -1, skips any
%      input checking or debugging, no figures will be generated, and sets
%      up code to maximize speed.
%
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
%     See the script: script_test_fcn_TimeClean_checkIfFieldHasRepeatedValues
%     for a full test suite.
%
% This function was written on 2024_11_07 by S. Brennan
% Questions or comments? sbrennan@psu.edu 

% REVISION HISTORY:
%     
% 2024_11_07 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally 
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - Changed in-use function name
%   % * From: fcn_LoadRawDataTo+MATLAB_pullDataFromFieldAcrossAllSensors
%   % * To: fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll

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
if (0==flag_max_speed)
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

% Does the user want to specify the sensors_to_check?
sensors_to_check = '';
if 4 <= nargin
    temp = varargin{2};
    if ~isempty(temp)
        sensors_to_check = temp;
    end
end


% Does the user want to specify the fid?
fid = 0;
if (0==flag_max_speed)
    % Check for user input
    if 5 <= nargin
        temp = varargin{3};
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


% Does user want to specify figNum?
flag_do_plots = 0;
if (0==flag_max_speed) &&  (6<=nargin)
    temp = varargin{end};
    if ~isempty(temp)
        figNum = temp;
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

if isempty(sensors_to_check)
    flag_check_all_sensors = 1;    
else
    flag_check_all_sensors = 0;
end

if flag_check_all_sensors
    flag_name = cat(2,field_name,'_has_no_repeats_in_all_sensors');
else
    flag_name = cat(2,field_name,sprintf('_has_no_repeats_in_%s_sensors',sensors_to_check));
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
    [~,sensor_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(dataStructure, field_name,sensors_to_check);
end


if 0~=fid
    fprintf(fid,'Checking for repeats in %s data ',field_name);
    if flag_check_all_sensors
        fprintf(fid,': --> %s\n', flag_name);
    else
        fprintf(fid,'in all %s sensors: --> %s\n', sensors_to_check, flag_name);
    end
end

for i_data = 1:length(sensor_names)
    % Grab the sensor subfield name
    sensor_name = sensor_names{i_data};   
    sensor_data = dataStructure.(sensor_name);
    
    if 0~=fid
        fprintf(fid,'\t Checking sensor %d of %d named %s: ',i_data,length(sensor_names),sensor_name);
    end
    
    [unique_values, IA, IC] = unique(sensor_data.(field_name),'rows','stable');
    
    % For debugging
    if 1==0
        disp([unique_values == sensor_data.(field_name) sensor_data.(field_name)])
    end
    % Don't compare NaN values
    if all(isnan(sensor_data.(field_name)))
        flag_no_repeats_detected = 1;
    else
        indiciesToTest = ~isnan(sensor_data.(field_name));
        NumNaNs = sum(~indiciesToTest);
        Numrepeats = length(IC) - length(IA);

        dataNoNaNs = sensor_data.(field_name)(indiciesToTest);
        if ~isequal(unique_values, dataNoNaNs)
            if 0~=fid
                fprintf(fid,'\t FAILED. Found %.0f NaNs and %.0f repeats.\n', NumNaNs,Numrepeats);
            end
            flag_no_repeats_detected = 0;
        else
            if 0~=fid
                fprintf(fid,'\t PASSED. \n');
            end
            flag_no_repeats_detected = 1;
        end
    end

    flags.(flag_name) = flag_no_repeats_detected;
    
    if 0==flags.(flag_name)
        offending_sensor = sensor_name; % Save the name of the sensor
        return_flag = 1; % Indicate that the return was forced
        if 0~=fid
            fprintf(fid,'\n\tExiting due to failure. Not all sensor checks complete.\n\tFlag %s set to: %.0f\n\n',flag_name, flag_no_repeats_detected);
        end

        return; % Exit the function immediately to avoid more processing
    end
end % Ends for loop


% Tell the user what is happening?
if 0~=fid
    fprintf(fid,'\n\tAll sensor checks complete.\n\tFlag %s set to: %.0f\n\n',flag_name, flag_no_repeats_detected);
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
if flag_do_plots && isempty(findobj('Number',figNum))

    % Nothing to plot
end

if  flag_do_debug
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

