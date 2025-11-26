function [flags,offending_sensor,return_flag] = fcn_TimeClean_checkDataStrictlyIncreasing(dataStructure, field_name, varargin)
% Checks that a field is strictly ascending, usually used for testing time
% or station fields.
%
% FORMAT:
%
%      [flags,offending_sensor,return_flag] = fcn_TimeClean_checkDataStrictlyIncreasing(dataStructure, field_name, (flags), (sensors_to_check), (fid), (figNum))
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
%      into the structure to allow a pass-through of flags structure.
%      Default is empty, e.g. to create a new structure.
%
%      sensors_to_check: a string listing the sensors to check. For
%      example, 'GPS' will check every sensor in the dataStructure whose
%      name contains 'GPS'. Default is empty, which checks all sensors.
%      Default is to check all the sensors.
%
%      fid: a file ID to print results of analysis. If not entered, no
%      output is given (default is FID = 0, e.g. no printing). Set fid to 1
%      for printing to console.
%
%      figNum: a figure number to plot results. If set to -1, skips any
%      input checking or debugging, no figures will be generated, and sets
%      up code to maximize speed. Default is no figure.
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
%      return_flag: flag is set to 1 if return is forced, e.g. an error was
%      found.
%
% DEPENDENCIES:
%
%      fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll
%
% EXAMPLES:
%
%     See the script: script_test_fcn_TimeClean_checkDataStrictlyIncreasing
%     for a full test suite.
%
% This function was written on 2023_07_01 by S. Brennan
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2024_11_06 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally, copying it out of INTERNAL function in
%   % checkDataTimeConsistency_GPS
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - Changed in-use function name
%   % * From: fcn_LoadRawDataTo+MATLAB_pullDataFromFieldAcrossAllSensors
%   % * To: fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll
%
% 2025_11_25 by Sean Brennan, sbrennan@psu.edu
% - Updated docstrings in header to show return_flag output

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

if 1==flag_check_all_sensors
    flag_name = sprintf('%s_strictly_ascends_in_all_sensors',field_name);
else
    flag_name = sprintf('%s_strictly_ascends_in_%s_sensors',field_name,sensors_to_check);
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
    fprintf(fid,'Checking that %s data is strictly ascending',field_name);
    if flag_check_all_sensors
        fprintf(fid,': ---> %s\n', flag_name);
    else
        fprintf(fid,' in all %s sensors:  ---> %s\n', sensors_to_check, flag_name);
    end
end

for i_data = 1:length(sensor_names)
    % Grab the sensor subfield name
    sensor_name = sensor_names{i_data};
    sensor_data = dataStructure.(sensor_name);
    
    if 0~=fid
        fprintf(fid,'\t Checking sensor %d of %d: %s\n',i_data,length(sensor_names),sensor_name);
    end
    flags_data_strictly_ascends= 1;
    % time_diff = diff(sensor_data.(field_name));
    sensor_value = sensor_data.(field_name);
    sensor_value_noNaN = sensor_value(~isnan(sensor_value));

    if ~issorted(sensor_value_noNaN,1,"strictascend")
        flags_data_strictly_ascends = 0;

        if 0~=fid
            fprintf(fid,'\t\t Sensor %s shows out-of-order data!\n',sensor_name);
            fprintf(fid,'\t\t\t Example output at point of failure:\n');

            header_strings = [{'Index'}, {'Data'},{'Jumps'}];
            formatter_strings = [{'%.0d'},{'%.5f'},{'%.5f'}];
            N_chars = 30; % All columns have same number of characters
            
            temp = diff(sensor_value);
            temp = [temp(1); temp]; %#ok<AGROW>
            indexOfFailure = find(temp<=0,1);
            NprintsNearby = 10;
            beforeIndex = max(indexOfFailure-NprintsNearby,1);
            afterIndex  = min(indexOfFailure+NprintsNearby,length(sensor_value));

            fullTable = [(1:length(sensor_value))' sensor_value temp];
            table_data = fullTable(beforeIndex:afterIndex,:);
            fcn_DebugTools_debugPrintTableToNCharacters(table_data, header_strings, formatter_strings,N_chars);



            % 
            % for ith_index = beforeIndex:afterIndex
            %     if ith_index~=indexOfFailure
            %         fprintf(fid,'\t\t\t %s \t %s \n',fcn_DebugTools_debugPrintStringToNCharacters(sprintf('%.5f',sensor_value(ith_index,1)),Nchars),fcn_DebugTools_debugPrintStringToNCharacters(sprintf('%.5f',temp(ith_index,1)),Nchars));
            %     else
            %         fcn_DebugTools_cprintf('Red','\t\t\t %s \t %s \n',fcn_DebugTools_debugPrintStringToNCharacters(sprintf('%.5f',sensor_value(ith_index,1)),Nchars),fcn_DebugTools_debugPrintStringToNCharacters(sprintf('%.5f',temp(ith_index,1)),Nchars));
            %     end
            % end
        end

    end
    
    if 0==return_flag && ~flags_data_strictly_ascends        
        return_flag = 1; % Indicate that the return was forced
    end

    if 0==flags_data_strictly_ascends
        if isempty(offending_sensor)
            offending_sensor = sensor_name;
        else
            offending_sensor = cat(2,offending_sensor,' ',sensor_name); % Save the name of the sensor
        end
        if 0~=fid
            fprintf(fid,'\t\t The following sensor is not strictly ascending %s\n',sensor_name);
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

