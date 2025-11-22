function newDataStructure = fcn_TimeClean_fillGPSTimeFromROSTime(mean_fit, filtered_median_errors, dataStructure, varargin)
% Calculates GPS time from ROS time
%
% FORMAT:
%
%      newDataStructure = fcn_TimeClean_fillGPSTimeFromROSTime(mean_fit, filtered_median_errors, dataStructure, (sensors_to_check), (fid), (fig_num))
%
% INPUTS:
%
%      mean_fit: an array of the mean fitting parameters, forcing the
%      slope to be 1
% 
%      filtered_median_errors: the filtered errors in the mean fit, for each
%      time parameter
%
%      dataStructure: a data structure to be analyzed
%
%      (OPTIONAL INPUTS)
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
%      fig_num: a figure number to plot results. If set to -1, skips any
%      input checking or debugging, no figures will be generated, and sets
%      up code to maximize speed. Default is no figure.
%
% OUTPUTS:
%
%      newDataStructure: a data structure with GPSfromROS_Time added to
%      each sensor
%
% DEPENDENCIES:
%
%      fcn_TimeClean_predictGPSTimeFromROSTime
%
% EXAMPLES:
%
%     See the script: script_test_fcn_TimeClean_fillGPSTimeFromROSTime
%     for a full test suite.
%
% This function was written on 2024_11_20 by S. Brennan
% Questions or comments? sbrennan@psu.edu

% Revision history:
%
% 2024_11_20: sbrennan@psu.edu
% -- wrote the code originally, copying it out of INTERNAL function in
% checkDataTimeConsistency_GPS

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the fig_num variable input
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
if (0==flag_max_speed)
    if flag_check_inputs
        % Are there the right number of inputs?
        narginchk(3,6);
    end
end

% Does the user want to specify the sensors_to_check?
sensors_to_check = '';
if 4 <= nargin
    temp = varargin{1};
    if ~isempty(temp)
        sensors_to_check = temp;
    end
end

% Does the user want to specify the fid?
fid = 0;
if (0==flag_max_speed)
    % Check for user input
    if 5 <= nargin
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
end


% Does user want to specify fig_num?
flag_do_plots = 0;
if (0==flag_max_speed) &&  (6<=nargin)
    temp = varargin{end};
    if ~isempty(temp)
        fig_num = temp;
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

newDataStructure = dataStructure;

if isempty(sensors_to_check)
    flag_check_all_sensors = 1;    
else
    flag_check_all_sensors = 0;
end

% if 1==flag_check_all_sensors
%     flag_name = sprintf('%s_strictly_ascends_in_all_sensors',field_name);
% else
%     flag_name = sprintf('%s_strictly_ascends_in_%s_sensors',field_name,sensors_to_check);
% end
% 
% % Initialize offending_sensor
% offending_sensor = '';
% return_flag = 0;

% Produce a list of all the sensors (each is a field in the structure)
if flag_check_all_sensors
    sensor_names = fieldnames(dataStructure); % Grab all the fields that are in dataStructure structure
else
    % Produce a list of all the sensors that meet the search criteria, and grab
    % their data also
    [~,sensor_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'ROS_Time',sensors_to_check);
end


if 0~=fid
    fprintf(fid,'Filling GPSfromROS_Time');
    if flag_check_all_sensors
        fprintf(fid,' in all sensors: \n');
    else
        fprintf(fid,' in all %s sensors:\n', sensors_to_check);
    end
end

for i_data = 1:length(sensor_names)
    % Grab the sensor subfield name
    sensor_name = sensor_names{i_data};
    sensor_data = dataStructure.(sensor_name);
    
    if 0~=fid
        fprintf(fid,'\t Filling sensor %d of %d: %s\n',i_data,length(sensor_names),sensor_name);
    end

    ROS_Time = sensor_data.ROS_Time;
    GPSfromROS_Time = fcn_TimeClean_predictGPSTimeFromROSTime(mean_fit, filtered_median_errors, ROS_Time);
    
    newDataStructure.(sensor_name).GPSfromROS_Time = GPSfromROS_Time;

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
if flag_do_plots && isempty(findobj('Number',fig_num))

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

