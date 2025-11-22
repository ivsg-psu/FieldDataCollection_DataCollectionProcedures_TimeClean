function GPSfromROS_Time = fcn_TimeClean_predictGPSTimeFromROSTime(mean_fit, filtered_median_errors, ROS_Time, varargin)
% fcn_TimeClean_predictGPSTimeFromROSTime
% Checks a given dataStructure to check, for each sensor, whether the field
% is there. If so, it sets a flag = 1 whose name is customized by the input
% settings. If not, it sets the flag = 0 and immediately exits.
%
% FORMAT:
%
%      GPSfromROS_Time = fcn_TimeClean_predictGPSTimeFromROSTime(...
%          mean_fit, filtered_median_errors, ROS_Time, (fid), (fig_num))
%
% INPUTS:
%
%      mean_fit: an array of the mean fitting parameters, forcing the
%      slope to be 1
% 
%      filtered_median_errors: the filtered errors in the mean fit, for each
%      time parameter
%
%      ROS_Time: the time vector to be converted into GPS time
%
%      (OPTIONAL INPUTS)
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
%      GPSfromROS_Time: the GPS time calculated from ROS time
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%     See the script: script_test_fcn_TimeClean_predictGPSTimeFromROSTime
%     for a full test suite.
%
% This function was written on 2024_11_20 by S. Brennan
% Questions or comments? sbrennan@psu.edu 

% Revision history:
%     
% 2024_11_20: sbrennan@psu.edu
% -- wrote the code originally 

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the fig_num variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
flag_max_speed = 0;
if (nargin==5 && isequal(varargin{end},-1))
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
        narginchk(3,5);
    end
end


% Does the user want to specify the fid?
fid = 0; %#ok<NASGU>
% Check for user input
if 4 <= nargin
    temp = varargin{1};
    if ~isempty(temp)
        % Check that the FID works
        try
            temp_msg = ferror(temp); %#ok<NASGU>
            % Set the fid value, if the above ferror didn't fail
            fid = temp; %#ok<NASGU>
        catch ME
            warning('on','backtrace');
            warning('User-specified FID does not correspond to a file. Unable to continue.');
            throwAsCaller(ME);
        end
    end
end

% Does user want to specify fig_num?
flag_do_plots = 0;
if (0==flag_max_speed) &&  (5<=nargin)
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

unitSlopeGPS_Time_estimated = ROS_Time + mean_fit(2);
adjustments = interp1(filtered_median_errors(:,1),filtered_median_errors(:,2),unitSlopeGPS_Time_estimated,'linear','extrap');
GPSfromROS_Time = unitSlopeGPS_Time_estimated + adjustments;

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

    % % Calculate GPS_Time_predicted - GPS_Time_actual, plot this versus duration
    % figure(fig_num);
    % clf;
    % 
    % tiledlayout('flow')
    % 
    % % Plot the fitting errors
    % nexttile
    % hold on;
    % grid on;
    % xlabel('Duration of Data Collection (seconds)');
    % ylabel('Deviations in Time (seconds)');
    % title('Regression fitting error for each sensor','Interpreter','none');
    % for ith_sensor = 1:length(sensor_names)
    %     this_GPS_Time = cell_array_GPS_Time{ith_array} - cell_array_GPS_Time{ith_array}(1,1);
    %     plot(this_GPS_Time,sensor_specific_fitting_errors{ith_sensor},'DisplayName',sensor_names{ith_sensor});
    % end
    % plot(this_GPS_Time,filtered_median_sensor_specific_errors,'Linewidth',3,'DisplayName','Mean error');
    % legend('Interpreter','none')
    % 
    % 
    % % Plot the GPS prediction errors
    % nexttile
    % hold on;
    % grid on;
    % xlabel('Duration of Data Collection (seconds)');
    % ylabel('Deviations in Time (seconds)');
    % title('Unit slope fitting error','Interpreter','none');
    % for ith_sensor = 1:length(sensor_names)
    %     this_GPS_Time = cell_array_GPS_Time{ith_array} - cell_array_GPS_Time{ith_array}(1,1);
    %     plot(this_GPS_Time,GPSfromROS_Time_errors{ith_sensor},'DisplayName',sensor_names{ith_sensor});
    % end
    % plot(this_GPS_Time,filtered_median_GPSfromROS_errors,'Linewidth',3,'DisplayName','Mean error');
    % legend('Interpreter','none')
    % 
    % 
    % 
    % % Plot histograms of GPS from ROS error
    % for ith_sensor = 1:length(sensor_names)
    %     nexttile
    %     histogram(GPSfromROS_Time_errors{ith_sensor},50);
    %     xlabel('Timing Error (sec)')
    %     ylabel('Count')
    %     title(cat(2,'Unit slope fit error for: ',sensor_names{ith_sensor}),'Interpreter','none');
    % end
    % nexttile
    % histogram(filtered_median_GPSfromROS_errors,50);
    % xlabel('Timing Error (sec)')
    % ylabel('Count')
    % title('Unit slope fit error, averaged across sensors','Interpreter','none');
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



