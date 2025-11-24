function [flags,offending_sensor,return_flag] = fcn_TimeClean_checkFieldDifferencesForMissings(dataStructure, field_name, varargin)
% fcn_TimeClean_checkFieldDifferencesForMissings
% Checks if the time step in all data matches expected centiSeconds, within
% a threshold. The purpose is to find if any data is missing.
%
% To detect missing data, the method is to calculate the actual time step
% in the field, and check if the difference between the actual and desired
% time step (e.g. the centiSeconds) is within a threshold.
%
% The input is a dataStructure with sensors as fields, and for
% each sensor there are subfields. For a given sub-field, for example
% position, this function takes differences in the position data (using
% diff) and checks whether the differences are unexpected, which could
% occur if there was a data drop. 
%
% If no missing data exist, it sets a flag = 1 whose name is customized
% by the input settings. If not, it sets the flag = 0 and immediately
% exits.
%
% FORMAT:
%
%      [flags,offending_sensor] = fcn_TimeClean_checkFieldDifferencesForMissings(...
%          dataStructure, field_name, ...
%          (flags),...
%          (threshold_for_agreement),...
%          (expectedJump),...
%          (string_any_or_all),(sensors_to_check),(fid))
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
%      threshold_for_agreement: the threshold for data to be missing. Data
%      would be flagged as missing if any difference in data jump is larger than
%      this threshold. Default is 1E-5;
%
%      expectedJump: the expected difference in the data. If empty
%      (default), threshold_for_agreement is set to the centiSeconds field
%      of the data converted to seconds.
%
%      string_any_or_all: a string consisting of 'any' or 'all' indicating
%      whether the data should be flagged if any sensor has jumps
%      ('any'), or if all sensors have jumps
%      ('all'). Default is 'any' if not specified or left empty ('');
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
%     See the script: script_test_fcn_TimeClean_checkFieldDifferencesForMissings
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
% - Updated comments
% - Added debug flag area
% - Fixed fid printing error
% 
% 2024_11_04 by Sean Brennan, sbrennan@psu.edu
% - Fixed header errors referring to old code
% - Added test script
% 
% 2024_11_14 by Sean Brennan, sbrennan@psu.edu
% - Changed flag naming to be consistent with other check functions, with
%    the sensor name first

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)



%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the figNum variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
flag_max_speed = 0;
if (nargin==8 && isequal(varargin{end},-1))
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
        narginchk(2,8);
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

% Does the user want to specify the threshold_for_agreement?
threshold_for_agreement = 1E-5;
if 4 <= nargin
    temp = varargin{2};
    if ~isempty(temp)
        threshold_for_agreement = temp;
    end
end

% Does the user want to specify the expectedJump?
expectedJump = []; % Default
if 5 <= nargin
    temp = varargin{3};
    if ~isempty(temp)
        expectedJump = temp;
    end
end


% Does the user want to specify the string_any_or_all?
string_any_or_all = 'any';
if 6 <= nargin
    temp = varargin{4};
    if ~isempty(temp)
        string_any_or_all = temp;
    end
end


% Does the user want to specify the sensors_to_check?
sensors_to_check = '';
if 7 <= nargin
    temp = varargin{5};
    if ~isempty(temp)
        sensors_to_check = temp;
    end
end


% Does the user want to specify the fid?
if (0==flag_max_speed)
    fid = 0;
    % Check for user input
    if 8 <= nargin
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

flag_do_plots = 0; % No plotting

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
flag_prefix = sprintf('%s_has_no_missing_sample_differences',field_name);

switch lower(string_any_or_all)
    case {'any'}
        if flag_check_all_sensors
            flag_name = sprintf('%s_in_any_sensors',flag_prefix);
        else
            flag_name = sprintf('%s_in_any_%s_sensors',flag_prefix,sensors_to_check);
        end
    case {'all'}
        if flag_check_all_sensors
            flag_name = sprintf('%s_in_all_sensors',flag_prefix);
        else
            flag_name = sprintf('%s_in_all_%s_sensors',flag_prefix, sensors_to_check);
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
    fprintf(fid,'Checking jumps in field: %s ',field_name);
    if flag_check_all_sensors
        fprintf(fid,':\n');
    else
        fprintf(fid,'in %s %s sensors:\n', string_any_or_all, sensors_to_check);
    end
end

% Loop through the sensor name list, checking each, and stopping
% immediately if we hit a bad case.

% Initialize all flags to 1 (default is that they are good)
sensors_pass_test_flags = ones(length(sensor_names),1);
for ith_sensor = 1:length(sensor_names)
    % Grab the sensor subfield name
    sensor_name = sensor_names{ith_sensor};
    sensor_data = dataStructure.(sensor_name);
    if isempty(expectedJump)
        expectedJump = sensor_data.centiSeconds*0.01;
    end
    
    % Tell the user what is happening?
    if 0~=fid
        fprintf(fid,'\t Checking sensor %d of %d: %s\n',ith_sensor,length(sensor_names),sensor_name);
    end
    
    % To detect jumps, the method is to calculate the difference in the field,
    % take the mean and standard deviation of the differences, then use a
    % threshold on standard deviations (default is 5). If any of the data fall
    % outside of this threshold, a jump error flag is set.
    
    
    flag_this_sensor_passes_test = 1;
    if ~isfield(sensor_data,field_name)
        flag_this_sensor_passes_test = 0;
    else
        testData = sensor_data.(field_name);
        differences_in_field_data = diff(testData);
        differences_in_field_data = [differences_in_field_data(1); differences_in_field_data]; %#ok<AGROW>
        jumps = abs(differences_in_field_data-expectedJump);
        if any(jumps>threshold_for_agreement)
            flag_this_sensor_passes_test = 0;
            if 0~=fid
                indexOfFailure = find(abs(differences_in_field_data-expectedJump)>threshold_for_agreement,1);

                fprintf(fid,'\t\t Sensor %s fails difference test!\n',sensor_name);
                fprintf(fid,'\t\t\t Expected jump: %.5f +/- %.5f\n',expectedJump, threshold_for_agreement);                
                fprintf(fid,'\t\t\t Example output at point of failure (index = %.0d):\n',indexOfFailure);

                header_strings = [{'Index'}, {'Data'},{'Jumps'}];
                formatter_strings = [{'%.0d'},{'%.5f'},{'%.5f'}];
                N_chars = 30; % All columns have same number of characters

                NprintsNearby = 10;
                beforeIndex = max(indexOfFailure-NprintsNearby,1);
                afterIndex  = min(indexOfFailure+NprintsNearby,length(testData));

                fullTable = [(1:length(testData))' testData differences_in_field_data];
                table_data = fullTable(beforeIndex:afterIndex,:);
                fcn_DebugTools_debugPrintTableToNCharacters(table_data, header_strings, formatter_strings,N_chars);
                %
                % for ith_index = beforeIndex:afterIndex
                %     fprintf(fid,'\t\t\t %s \t %s \n',fcn_DebugTools_debugPrintStringToNCharacters(sprintf('%.5f',testData(ith_index,1)),Nchars),fcn_DebugTools_debugPrintStringToNCharacters(sprintf('%.5f',differences_in_field_data(ith_index,1)),Nchars));
                % end
            end
        end
    end
    sensors_pass_test_flags(ith_sensor,1) = flag_this_sensor_passes_test;

end

flag_field_passes_test = 1;
% Check the all case
if strcmp(string_any_or_all,'all') && all(sensors_pass_test_flags==0)
    % If any sensors have to have the field, then if all are nan, this
    % flag fails
    flag_field_passes_test = 0;
    first_failure = 1;
    offending_sensor = sensor_names{first_failure};
end

% Check the any case
if strcmp(string_any_or_all,'any') && any(sensors_pass_test_flags==0)
    % If any sensors have to have the field, then if all are nan, this
    % flag fails
    flag_field_passes_test = 0;
    first_failure = find(sensors_pass_test_flags==0,1,'first');
    offending_sensor = sensor_names{first_failure};
end

% Set the flag array and return accordingly
flags.(flag_name) = flag_field_passes_test;
if 0==flags.(flag_name)
    return_flag = 1; % Indicate that the return was forced
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



