function fixed_dataStructure = fcn_TimeClean_fillMissingsInGPSUnits(dataStructure,varargin)
% fcn_TimeClean_fillMissingsInGPSUnits
% Interpolate the GPS_Time field for all GPS sensors. This is done by
% using the centiSeconds field and the effective start and end GPS_Times,
% determined by taking the maximum start time and minimum end time over all
% sensors.
%
% FORMAT:
%
%      fixed_dataStructure = fcn_TimeClean_fillMissingsInGPSUnits(dataStructure, (fid), (figNum))
%
% INPUTS:
%
%      dataStructure: a data structure to be analyzed that includes the following
%      fields:
%
%      (OPTIONAL INPUTS)
%
%      fid: a file ID to print results of analysis. If not entered, no
%      output is given (FID = 0). Set fid to 1 for printing to console.
%
%      figNum: a figure number to plot results. If set to -1, skips any
%      input checking or debugging, no figures will be generated, and sets
%      up code to maximize speed.
%
% OUTPUTS:
%
%      fixed_dataStructure: a data structure to be analyzed that includes the following
%      fields:
%
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%
% EXAMPLES:
%
%      See script_test_fcn_TimeClean_fillMissingsInGPSUnits
%
% This function was written on 2024_08_15 by X. Cao
% Questions or comments? xfc5113@psu.edu

% REVISION HISTORY:
% 
% 2024_10_08 by Sean Brennan, sbrennan@psu.edu
% - Added test cases
% - Updated top comments
% - Added debug flag area
% - Fixed fid printing error
% - Added figNum input, fixed the plot flag
% - Fixed warning and errors
% - Removed interpolation of GPS data itself (gives errors)
% 
% 2024_10_13 - X. Cao
% - add another condition to the if statement in line 278, currently
%    eventFunctions field is an empty cell, no interpolation process is
%    needed
% 
% 2024_12_07 by Sean Brennan, sbrennan@psu.edu
% - Fixed bug where interpolation fails if NaN is present

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)


%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the figNum variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
MAX_NARGIN = 3; % The largest Number of argument inputs to the function
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
fid = 0;
if (0==flag_max_speed)
    % Check for user input
    if 2 <= nargin
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
end


% Does user want to specify figNum?
flag_do_plots = 0;
if (0==flag_max_speed) &&  (MAX_NARGIN==nargin)
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

% The method this is done is to:
% 1. Find the effective start and end GPS_Times, determined by taking the maximum start time and minimum end time over all
% sensors.
% 2.  Fill and interpolate the missing data in GPS units


%% Step 1: Find the effective start and end GPS and ROS times over all sensors


[cell_array_GPS_Time, sensor_names_GPS_Time] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'GPS_Time','GPS');
[~, sensor_names_ROS_Time]  = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'ROS_Time','GPS');

if ~isequal(sensor_names_GPS_Time,sensor_names_ROS_Time)
    warning('on','backtrace');
    warning('Inconsistent GPS and ROS time fields.');
    error('Sensors were found that were missing either GPS_Time or ROS_Time. Unable to interpolate.');
end

% Grab the centiSeconds, and make sure all are the same.
[cell_array_centiSeconds, ~] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'centiSeconds','GPS');
all_centiSeconds = cell2mat(cell_array_centiSeconds);
centiSeconds = all_centiSeconds(1);

if ~all(all_centiSeconds==all_centiSeconds(1))
    warning('on','backtrace');
    warning('Inconsistent GPS time sample intervals detected. Code is not yet written to support GPS units with inconsistent sampling rates. Forced to exit.');
    error('Sensors were found with inconsistent sampling rates. Unable to interpolate.');
end


N_GPS_Units = length(cell_array_GPS_Time);

%% Define fields that need to be interpolated

timeFieldsToInterpolate=[
    "ROS_Time",...
    "GPS_Time"];


%% Find min/max of GPS_Time in the subfields
% Goal: to force all to have the same start/end GPS_Time. To do this, we
% need to know the start and end time. The start time is the maximum
% GPS_Time among all the first GPS_Times. The end time is the minimum
% GPS_Time among all the last GPS_Times.

start_GPSTime = -inf;
end_GPSTime = inf;

for index_GPSUnit = 1:N_GPS_Units
    thisGPSTimeData = cell_array_GPS_Time{index_GPSUnit};
    start_GPSTime = max([start_GPSTime,min(thisGPSTimeData)]);
    end_GPSTime   = min([end_GPSTime,  max(thisGPSTimeData)]);
end


% Make sure we choose a time that all the sensors CAN start at. We round
% start seconds up, and end seconds down.
start_GPSTime_centiSeconds = round(100*start_GPSTime/centiSeconds)*centiSeconds;
end_GPSTime_centiSeconds = round(100*end_GPSTime/centiSeconds)*centiSeconds;
fixed_GPSTime_centiSeconds = (start_GPSTime_centiSeconds:centiSeconds:end_GPSTime_centiSeconds).';
fixed_GPSTime = fixed_GPSTime_centiSeconds/100;


%% Interate over GPS units and interpolate data in each field
fixed_dataStructure = dataStructure;
beforeData = cell(N_GPS_Units,1);
afterData  = cell(N_GPS_Units,1);

for idx_gps_unit = 1:N_GPS_Units
    GPSUnitName = sensor_names_GPS_Time{idx_gps_unit};
    GPSdataStructure = fixed_dataStructure.(GPSUnitName);
    sub_fields = fieldnames(GPSdataStructure);
    N_fields = length(sub_fields);

    % Grab the original_GPS_Time, and create an index
    original_GPS_Time = cell_array_GPS_Time{idx_gps_unit};
    NpointsOriginalTime = length(original_GPS_Time);

    % Fix GPS time
    originalGPS_timeData = GPSdataStructure.GPS_Time;
    GPSdataStructure.GPS_Time = fixed_GPSTime;    
    NpointsCorrectedTime = length(fixed_GPSTime(:,1));
    % indiciesInRange = ((originalGPS_timeData>=start_GPSTime).*(originalGPS_timeData<=end_GPSTime))==1;
    % originalGPS_timeDataInRange = originalGPS_timeData(find(indiciesInRange)); %#ok<FNDSB>
    % NpointsOriginalTimeInRange = length(originalGPS_timeDataInRange);
    % indexOriginalTimeInRange = (1:NpointsOriginalTimeInRange)';

    % Save the before/after
    beforeData{idx_gps_unit} = originalGPS_timeData;
    afterData{idx_gps_unit}  = fixed_GPSTime;
    differences = abs(originalGPS_timeData - fixed_GPSTime);
    timeThreshold = 1E-6; % Times must agree to within a microsecond to be same
    badIndicies = [find(differences>timeThreshold); find(isnan(differences))];


    % % Check which indicies changed. The reason for this is that we need to
    % % know which indicies were bad in the GPS data. The data with these
    % % indicies is also bad and needs to be fixed.
    % nonNanIndicies = ~isnan(originalGPS_timeData);
    % changedIndicies = interp1(originalGPS_timeData(nonNanIndicies), indexOriginalTime(nonNanIndicies), fixed_GPSTime,'linear',"extrap");
    % indiciesUnchangedFlagsInterpCheck = abs(round(changedIndicies)-changedIndicies)<=timeThreshold;
    % changedIndicies(indiciesUnchangedFlagsInterpCheck==0) = 0;
    % changedIndiciesRounded = round(changedIndicies(changedIndicies~=0));
    % 
    % % Make sure that the number of indicies to change is not larger than
    % % expected. This should never happen as the interp1 function should
    % % always push out a data length equal to fixed_GPSTime
    % assert(length(changedIndicies)<=length(fixed_GPSTime),...
    %     sprintf('The number of points to be saved: %.0d, is greater than the number of GPS time points: %.0d.',length(changedIndicies), length(fixed_GPSTime)));    
    % 
    % % Make sure we are not querying data outside of the data range
    % assert(max(changedIndicies)<=NpointsOriginalTime,...
    %     sprintf('The highest index to query: %.0d, is greater than the number of points in a data set: %.0d.',max(changedIndicies), NpointsOriginalTime));
    % 
    % % Make sure the indicies, when applied to time, produce exactly the
    % % same results
    % originalTimes = original_GPS_Time(changedIndiciesRounded);
    % fixedTimes = fixed_GPSTime(indiciesUnchangedFlagsInterpCheck);
    % differences = originalTimes - fixedTimes;
    % assert(all(abs(differences)<1E6),...
    %     sprintf('The rounded times, using change indicies, does not match the intended GPS times. Unable to continue.'));


    % Loop through all the fields. If they contain any time fields,
    % interpolate them. If they don't, fill with NaN by default, and then fix them.     
    for idx_field = 1:N_fields
        sub_field = sub_fields{idx_field};
        current_fieldData = GPSdataStructure.(sub_field);
        
        % Is the field NOT GPS_Time (which was already fixed)
        % AND
        % Is the field NOT empty (EventFunction field)
        if ~strcmp(sub_field,'GPS_Time') && ~isempty(current_fieldData)

            % If the data contain more than 1 value, and if the name contains
            % "GPS_Time, ROS_Time", etc, then need to interpolate it.
            if (length(current_fieldData)>1) && (any(contains(timeFieldsToInterpolate,sub_field)))

                % % Which type of interpolation to use?
                % interp_method = fcn_TimeClean_determineInterpolateMethod(sub_field);

                % Perform interpolation
                nonNanIndicies = ~isnan(original_GPS_Time);
                current_field_interp = interp1(original_GPS_Time(nonNanIndicies),current_fieldData(nonNanIndicies),fixed_GPSTime,'linear',"extrap");
                GPSdataStructure.(sub_field) = current_field_interp;
            elseif length(current_fieldData(:,1))==NpointsOriginalTime
                % Fill with Nan by default. Note: data may have many columns so
                % use size to find how many
                % sizeOfData = size(current_fieldData);
                
                current_fieldDataNanInserted = current_fieldData;
                current_fieldDataNanInserted(badIndicies,:) = nan;
                
                GPSdataStructure.(sub_field) = current_fieldDataNanInserted;
            elseif isscalar(current_fieldData(:,1))
                % Save it
                GPSdataStructure.(sub_field) = current_fieldData;
            else
                warning('on','backtrace');
                warning('Found a field of name: %s with mismatched number of rows: %.0d. Expecting %.0d data points.',sub_field, NpointsOriginalTime, length(current_fieldData(:,1)));
            end
        end
    end

    % Fill the time-associated fields
    GPSdataStructure.centiSeconds = centiSeconds;
    GPSdataStructure.Npoints = NpointsCorrectedTime;

    fixed_dataStructure.(GPSUnitName) = GPSdataStructure;
end % Ends for loop


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

    % check whether the figure already has data
    temp_h = figure(figNum);
    flag_rescale_axis = 0;
    if isempty(get(temp_h,'Children'))
        flag_rescale_axis = 1;
    end

    for idx_gps_unit = 1:N_GPS_Units

        % Get the before/after
        originalGPS_timeData = beforeData{idx_gps_unit};
        originalGPS_timeData = originalGPS_timeData - originalGPS_timeData(1,1);
        fixed_GPSTime = afterData{idx_gps_unit};
        fixed_GPSTime = fixed_GPSTime - fixed_GPSTime(1);

        nexttile

        % Plot the data
        % Prep this as a stair-step plot
        [xdata,ydata] = fcn_INTERNAL_stairStep(originalGPS_timeData);
        plot(xdata, ydata);
        hold on;
        [xdata,ydata] = fcn_INTERNAL_stairStep(fixed_GPSTime);
        plot(xdata, ydata);

        legend('Before','After');
        xlabel('Index [unitless]');
        ylabel('Change in Time [sec]')
        title(sprintf('%s',sensor_names_GPS_Time{idx_gps_unit}),'interpreter','none','FontSize',12)

        % Make axis slightly larger?
        if flag_rescale_axis
            temp = axis;
            %     temp = [min(points(:,1)) max(points(:,1)) min(points(:,2)) max(points(:,2))];
            axis_range_x = temp(2)-temp(1);
            axis_range_y = temp(4)-temp(3);
            percent_larger = 0.3;
            axis([temp(1)-percent_larger*axis_range_x, temp(2)+percent_larger*axis_range_x,  temp(3)-percent_larger*axis_range_y, temp(4)+percent_larger*axis_range_y]);
        end


    end


    
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
function [xdata,ydata] = fcn_INTERNAL_stairStep(dataToStairStep)

xdataUnrepeated = (1:length(dataToStairStep));
xdataRepeated = repmat(xdataUnrepeated,2,1);
xdataRearranged = reshape(xdataRepeated,[],1);

ydataUnrepeated = dataToStairStep';
ydataRepeated = repmat(ydataUnrepeated,2,1);
ydataRearranged = reshape(ydataRepeated,[],1);

xdata = xdataRearranged(2:end,1);
ydata = ydataRearranged(1:end-1,1);

end % Ends fcn_INTERNAL_stairStep
