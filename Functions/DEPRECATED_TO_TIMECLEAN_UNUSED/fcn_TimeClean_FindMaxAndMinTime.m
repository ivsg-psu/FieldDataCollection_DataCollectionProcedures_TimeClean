function time_range = fcn_TimeClean_FindMaxAndMinTime(dataStructure,time_type)

% fcn_TimeClean_FindMaxAndMinTime finds the start and end time for
% each sensor
%
% FORMAT:
%
% time_range = fcn_TimeClean_FindMaxAndMinTime(dataStructure,time_type)
%
%
% INPUTS:
%
%      dataStructure: a structure array containing raw data
%
%       time_type: ROS_Time,GPS_Time or Trigger_Time
%
% OUTPUTS:
%
%      time_range: a array containing start and end time
%
%
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%      fcn_geometry_plotCircle
%
% EXAMPLES: to be done
%      
%
% 
%
% This function was written on 2023_10_20 by X.Cao
% Questions or comments? xfc5113@psu.edu

% Revision history:
% 2023_10_20 - wrote the code
% 2024_01_28 - added more comments, particularly to explain inputs more
% clearly

%% Debugging and Input checks
flag_do_debug = 1;
if flag_do_debug
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
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
flag_check_inputs = 1; % Flag to perform input checking

if flag_check_inputs == 1
    if ~isstruct(dataStructure)
        error('The input of the function should be a structure array')
    end

end

%% Solve for the angle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _       
%  |  \/  |     (_)      
%  | \  / | __ _ _ _ __  
%  | |\/| |/ _` | | '_ \ 
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


fields = fieldnames(dataStructure);
sensor_centiSeconds = [];
start_times_centiSeconds = [];
end_times_centiSeconds = [];
% start_times = [];
% end_times = [];
for idx_field = 1:length(fields)
    current_field_struct = dataStructure.(fields{idx_field});
    if ~isempty(current_field_struct)
        
       current_field_struct_time = current_field_struct.(time_type);
       current_field_centiSeconds = current_field_struct.centiSeconds;
        
    end
    ROSTime_centiSeconds = round(100*current_field_struct_time/current_field_centiSeconds)*current_field_centiSeconds;
    sensor_centiSeconds = [sensor_centiSeconds; current_field_centiSeconds]; %#ok<AGROW>
    start_times_centiSeconds = [start_times_centiSeconds; ROSTime_centiSeconds(1)]; %#ok<AGROW>
    end_times_centiSeconds = [end_times_centiSeconds; ROSTime_centiSeconds(end)]; %#ok<AGROW>



end
% Take the maximum start time and minimum end time and assign these to the
% global start and end times.
master_start_time_centiSeconds = max(start_times_centiSeconds);
master_end_time_centiSeconds = min(end_times_centiSeconds);

% Make sure we choose a time that all the sensors CAN start at. We round
% start seconds up, and end seconds down.
master_start_time_Seconds = ceil(master_start_time_centiSeconds/100);
master_end_time_Seconds = (master_end_time_centiSeconds/100);

time_range = [master_start_time_Seconds, master_end_time_Seconds];

    
end
