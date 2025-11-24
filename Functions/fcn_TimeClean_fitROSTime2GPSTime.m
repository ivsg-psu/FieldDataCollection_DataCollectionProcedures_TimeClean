function [flags, fitting_parameters, fit_sensors, mean_fit, filtered_median_errors] = fcn_TimeClean_fitROSTime2GPSTime(dataStructure, varargin)
% fcn_TimeClean_fitROSTime2GPSTime
% Calculated the model that fits GPS time to ROS time.
%
% FORMAT:
%
%      [flags, fitting_parameters, fit_sensors, mean_fit, filtered_median_errors] = fcn_TimeClean_fitROSTime2GPSTime(...
%          dataStructure, (fid), (figNum))
%
% INPUTS:
%
%      dataStructure: a data structure to be analyzed
%
%      (OPTIONAL INPUTS)
%
%      flags: If a structure is entered, it will append the flag result
%      into the structure to allow a pass-through of flags structure
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
%      flags: a data structure containing subfields that define the results
%      of the verification check. The name of the flag is formatted by the
%      argument inputs. 
%
%      fitting_parameters: a cell array of fit parameters, one for each GPS
%      sensor
%
%      fit_sensors: a cell array of the string names of each GPS sensor used
%      for fitting
%
%      mean_fit: an array of the mean fitting parameters, forcing the
%      slope to be 1
% 
%      filtered_median_errors: the filtered errors in the mean fit, for each
%      time parameter
%
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%
% EXAMPLES:
%
%     See the script: script_test_fcn_TimeClean_fitROSTime2GPSTime
%     for a full test suite.
%
% This function was written on 2023_06_19 by S. Brennan
% Questions or comments? sbrennan@psu.edu 

% REVISION HISTORY:
%     
% 2024_11_18 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally 

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
    if flag_check_inputs
        % Are there the right number of inputs?
        narginchk(1,4);
    end
end

% Does the user want to specify the flags?
flags = struct;
if 2 <= nargin
    temp = varargin{1};
    if ~isempty(temp)
        flags = temp;
    end
end


% Does the user want to specify the fid?
fid = 0;
% Check for user input
if 3 <= nargin
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

% Does user want to specify figNum?
flag_do_plots = 0;
if (0==flag_max_speed) &&  (4<=nargin)
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

% Set up output flag name string
flag_name = 'ROS_Time_calibrated_to_GPS_Time';


% Tell the user what is happening?
if 0~=fid
    fprintf(fid,'Calibrating ROS time to GPS time');
    fprintf(fid,': --> %s\n', flag_name);    
end
    

% Examine the offset deviations between the different time sources
[cell_array_centiSeconds,~]        = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'centiSeconds','GPS');
[cell_array_GPS_Time,~]            = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'GPS_Time',    'GPS');
[cell_array_ROS_Time,sensor_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'ROS_Time',    'GPS');

fit_sensors = sensor_names;

% Make sure that length of GPS Times and ROS Times match
for ith_array = 1:length(cell_array_GPS_Time)
    NdataGPS_Time = length(cell_array_GPS_Time{ith_array}(:,1));
    NdataROS_Time = length(cell_array_ROS_Time{ith_array}(:,1));
    if NdataGPS_Time~=NdataROS_Time
        warning('on','backtrace');
        warning('Fundamental error on ROS_time: count does not match GPS time');
        error('Number of GPS and ROS time points must match!');
    end
end

% Make sure the centiSeconds times, across GPS sensors, are the same
referenceInterval = cell_array_centiSeconds{1};
for ith_array = 1:length(cell_array_GPS_Time)
    assert(cell_array_centiSeconds{ith_array}==referenceInterval);
end

% Make sure the GPS times, across GPS sensors, are the same length
Npoints = length(cell_array_GPS_Time{1}(:,1));
for ith_array = 1:length(cell_array_GPS_Time)
    assert(length(cell_array_GPS_Time{ith_array}(:,1))==Npoints);
end

% Make sure the GPS times, across GPS sensors, are the same entries, within
% the centiSeconds interval
referenceGPS = cell_array_GPS_Time{ith_array};
for ith_array = 1:length(cell_array_GPS_Time)
    thisGPS_Time = cell_array_GPS_Time{ith_array};
    differences = thisGPS_Time - referenceGPS;
    assert(max(abs(differences))<referenceInterval);
end

%% Perform regressions
fitting_parameters       = cell(length(cell_array_GPS_Time),1);
sensor_specific_fitting_errors  = cell(length(cell_array_GPS_Time),1);
sensor_specific_unit_slope_intercepts = nan(length(cell_array_GPS_Time),1);

for ith_array = 1:length(cell_array_GPS_Time)
    this_GPS_Time = cell_array_GPS_Time{ith_array} - cell_array_GPS_Time{ith_array}(1,1);
    this_ROS_Time = cell_array_ROS_Time{ith_array} - cell_array_GPS_Time{ith_array}(1,1);
    fullX = [this_ROS_Time ones(length(this_ROS_Time(:,1)),1)];  % Includes NaN values

    % Remove NaN values to have "clean" regression data
    good_y_indicies = ~isnan(this_GPS_Time);
    good_x_indicies = ~isnan(this_ROS_Time);
    good_indicies   = good_y_indicies & good_x_indicies;
    assert(length(good_indicies)>=2); % Make sure there are good indicies for regression
    regression_y = this_GPS_Time(good_indicies);
    regression_x = this_ROS_Time(good_indicies);



    % Perform regression fit
    % y = [x 1]*m
    % X'*y = (X'*X)*m
    % m = (X'*X)*(X'*y)    
    Ndata = length(regression_x);
    X = [regression_x ones(Ndata,1)];  % No NaN values
    y = regression_y; % No NaN values
    m = (X'*X)\(X'*y);
    fitting_parameters{ith_array} = m;

    this_GPS_Time_predicted = fullX*m;
    sensor_specific_fitting_errors{ith_array} = this_GPS_Time - this_GPS_Time_predicted;

    this_timeDifference = this_GPS_Time - this_ROS_Time;
    mean_this_timeDifference = mean(this_timeDifference);
    sensor_specific_unit_slope_intercepts(ith_array,1) = mean_this_timeDifference;
end

% Find the average fitting error and smooth it
mean_sensor_specific_errors = mean([sensor_specific_fitting_errors{:}],2);
median_sensor_specific_errors =  medfilt1(mean_sensor_specific_errors,7,'truncate','omitnan');
[b,a] = butter(2,0.1);
try
    filtered_median_sensor_specific_errors = filtfilt(b,a,median_sensor_specific_errors);
catch
    error('Stop here');
end

return_flag = 1;

% Find the average intercept, assuming unit slope
meanIntercept = mean(sensor_specific_unit_slope_intercepts);

% Find errors relative to mean fit
mean_fit = mean([fitting_parameters{:}],2);
tolerance = 1E-3;
slope = mean_fit(1);
if abs(slope-1)>tolerance
    warning('on','backtrace');
    warning('ROS time is gaining/losing more than a millisecond per second?!');
    error('Slope relating change in time in ROS to GPS change in time is unexpectedly in error. Forced quit!');
end

% Note that the linear regression slope term adds a VERY small amount of
% offset error. We have to avoid this!
if 1==0
    disp([mean_fit(2); mean(sensor_specific_unit_slope_intercepts)])
end

% Adjust the mean fit to force unit slope
mean_fit(1) = 1; % Force slope to be 1
mean_fit(2) = meanIntercept;

% Find the fitting error for each sensor, relative to the unit-slope fit
fitting_errors  = cell(length(cell_array_GPS_Time),1); % Preallocate the data
for ith_array = 1:length(cell_array_GPS_Time)
    this_GPS_Time = cell_array_GPS_Time{ith_array} - cell_array_GPS_Time{ith_array}(1,1);
    this_ROS_Time = cell_array_ROS_Time{ith_array} - cell_array_GPS_Time{ith_array}(1,1);
    Ndata = length(this_ROS_Time(:,1));
    fullX = [this_ROS_Time ones(Ndata,1)];  % Includes NaN values
    this_GPS_Time_predicted = fullX*mean_fit;
    fitting_errors{ith_array} = this_GPS_Time - this_GPS_Time_predicted;
end

% Find the average fitting error and smooth it
mean_errors = mean([fitting_errors{:}],2);
median_errors =  medfilt1(mean_errors,7,'truncate');
[b,a] = butter(2,0.1);
filtered_median_errors_x = cell_array_GPS_Time{1};
filtered_median_errors_y = filtfilt(b,a,median_errors);
filtered_median_errors = [filtered_median_errors_x filtered_median_errors_y];

% Check the fit
GPSfromROS_Time        = cell(length(cell_array_GPS_Time),1); % Preallocate the data
GPSfromROS_Time_errors = cell(length(cell_array_GPS_Time),1); % Preallocate the data
for ith_array = 1:length(cell_array_ROS_Time)
    ROS_Time = cell_array_ROS_Time{ith_array};
    GPSfromROS_Time{ith_array} = fcn_TimeClean_predictGPSTimeFromROSTime(mean_fit, filtered_median_errors, ROS_Time);

    % unitSlopeGPS_Time_estimated = cell_array_ROS_Time{ith_array} + mean_fit(2);
    % adjustments = interp1(filtered_median_errors(:,1),filtered_median_errors(:,2),unitSlopeGPS_Time_estimated,'linear','extrap');
    % GPSfromROS_Time{ith_array} = unitSlopeGPS_Time_estimated + adjustments;
    GPSfromROS_Time_errors{ith_array} = GPSfromROS_Time{ith_array} - cell_array_GPS_Time{ith_array};
end

% Find the average fitting error from fitting
mean_GPSfromROS_errors = mean([GPSfromROS_Time_errors{:}],2);
median_GPSfromROS_errors =  medfilt1(mean_GPSfromROS_errors,7,'truncate');
[b,a] = butter(2,0.1);
filtered_median_GPSfromROS_errors = filtfilt(b,a,median_GPSfromROS_errors);


if 0==return_flag
    flags.(flag_name) = 0;
else
    flags.(flag_name) = 1;
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

    % Calculate GPS_Time_predicted - GPS_Time_actual, plot this versus duration
    figure(figNum);
    clf;

    tiledlayout('flow')
       
    % Plot the fitting errors
    nexttile
    hold on;
    grid on;
    xlabel('Duration of Data Collection (seconds)');
    ylabel('Deviations in Time (seconds)');
    title('Regression fitting error for each sensor','Interpreter','none');
    for ith_sensor = 1:length(sensor_names)
        this_GPS_Time = cell_array_GPS_Time{ith_array} - cell_array_GPS_Time{ith_array}(1,1);
        plot(this_GPS_Time,sensor_specific_fitting_errors{ith_sensor},'DisplayName',sensor_names{ith_sensor});
    end
    plot(this_GPS_Time,filtered_median_sensor_specific_errors,'Linewidth',3,'DisplayName','Mean error');
    legend('Interpreter','none')


    % Plot the GPS prediction errors
    nexttile
    hold on;
    grid on;
    xlabel('Duration of Data Collection (seconds)');
    ylabel('Deviations in Time (seconds)');
    title('Unit slope fitting error','Interpreter','none');
    for ith_sensor = 1:length(sensor_names)
        this_GPS_Time = cell_array_GPS_Time{ith_array} - cell_array_GPS_Time{ith_array}(1,1);
        plot(this_GPS_Time,GPSfromROS_Time_errors{ith_sensor},'DisplayName',sensor_names{ith_sensor});
    end
    plot(this_GPS_Time,filtered_median_GPSfromROS_errors,'Linewidth',3,'DisplayName','Mean error');
    legend('Interpreter','none')



    % Plot histograms of GPS from ROS error
    for ith_sensor = 1:length(sensor_names)
        nexttile
        histogram(GPSfromROS_Time_errors{ith_sensor},50);
        xlabel('Timing Error (sec)')
        ylabel('Count')
        title(cat(2,'Unit slope fit error for: ',sensor_names{ith_sensor}),'Interpreter','none');
    end
    nexttile
    histogram(filtered_median_GPSfromROS_errors,50);
    xlabel('Timing Error (sec)')
    ylabel('Count')
    title('Unit slope fit error, averaged across sensors','Interpreter','none');
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



