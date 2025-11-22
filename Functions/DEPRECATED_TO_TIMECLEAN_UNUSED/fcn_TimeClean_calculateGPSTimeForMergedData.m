function matched_GPS_Time_fixed = fcn_TimeClean_calculateGPSTimeForMergedData(ROS_Time,GPS_Time,centiSeconds,offset_between_GPSTime_and_ROSTime)

% fcn_TimeClean_calculateGPSTimeForMergedData
% Calculate GPS time for nmea sentences without GPS time
% FORMAT:
%
%      matched_GPS_Time_fixed = fcn_TimeClean_calculateGPSTimeForMergedData(ROS_Time,GPS_Time,centiSeconds,offset_between_GPSTime_and_ROSTime)
%
% INPUTS:
%
%      ROS_Time: ROS Time of the NMEA sentences without GPS Time
%
%      GPS_Time: GPS Time of the GPS unit
%
%      centiSeconds: centiSecond of the GPS unit
%
%      offset_between_GPSTime_and_ROSTime: offset between the GPS_Time and
%      ROS_Time of the NMEA sentences with GPS_Time
%
% OUTPUTS:
%
%      matched_GPS_Time_fixed: calculated GPS_Time for the NMEA sentences
%
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%
% EXAMPLES: # To be Done
%
%
% This function was written on 2024_08_15 by X. Cao
% Questions or comments? xfc5113@psu.edu

% Revision history:
%     
% TO DO

% Set default fid (file ID) first:
flag_do_debug = 1;  %#ok<NASGU> % Flag to show the results for debugging
flag_do_plots = 0;  % % Flag to plot the final results
flag_check_inputs = 1; % Flag to perform input checking


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

if flag_check_inputs
    % Are there the right number of inputs?
    if nargin < 4 || nargin > 4
        error('Incorrect number of input arguments')
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
% 1. Round the ROS_Time for the NMEA sentence
% 2. Calculate the GPS_Time for the NMEA sentence

%% Step 1: Round the ROS_Time 
rounded_centiSecond_ROS_Time = round(ROS_Time*100/centiSeconds)*centiSeconds;
rounded_centiSecond_ROS_Time_diff = diff(rounded_centiSecond_ROS_Time);
ROS_Time_strictly_ascends = all(rounded_centiSecond_ROS_Time_diff>0);
rounded_centiSecond_ROS_Time_fixed = rounded_centiSecond_ROS_Time;

if ROS_Time_strictly_ascends == 0
    tf_flat = (rounded_centiSecond_ROS_Time_diff == 0);
    rounded_centiSecond_ROS_Time_fixed(tf_flat) = nan;
    rounded_centiSecond_ROS_Time_fixed = fillmissing(rounded_centiSecond_ROS_Time_fixed,'linear');
end
centiSecond_ROS_Time_fixed = rounded_centiSecond_ROS_Time_fixed/100;
calculated_GPS_Time = centiSecond_ROS_Time_fixed - mean(offset_between_GPSTime_and_ROSTime);
%% Step 2: Calculate the GPS_Time
matched_GPS_Time = zeros(size(centiSecond_ROS_Time_fixed));
for idx_time = 1:length(calculated_GPS_Time)
    time_diff = abs(GPS_Time-calculated_GPS_Time(idx_time));
    [~,closest_idx] = min(time_diff);
    matched_GPS_Time(idx_time,:) = GPS_Time(closest_idx);
end

tf_flat_matched_GPS_Time = (diff(matched_GPS_Time) == 0);
matched_GPS_Time_fixed = matched_GPS_Time;
matched_GPS_Time_fixed(tf_flat_matched_GPS_Time) = nan;
matched_GPS_Time_fixed = fillmissing(matched_GPS_Time_fixed,'linear');
