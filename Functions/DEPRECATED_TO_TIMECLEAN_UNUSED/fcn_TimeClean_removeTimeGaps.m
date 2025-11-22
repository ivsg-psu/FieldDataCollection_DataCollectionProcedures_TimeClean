function RawDataWithoutTimeGaps = fcn_TimeClean_removeTimeGaps(rawData)


% fcn_TimeClean_removeTimeGaps finds the start and end time for
% each sensor
%
% FORMAT:
%
% time_range = fcn_DataPreprocessing_FindMaxAndMinTime(rawDataStructure)
%
% INPUTS:
%
%      GPS_rawdata_struct: a structure array containing raw GPS data
%
%
% OUTPUTS:
%
%      GPS_Locked_data_struct: a structure array containing locked GPS data
%
%
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%      fcn_geometry_plotCircle
%
% EXAMPLES:
%      
%      % BASIC example
%      points = [0 0; 1 4; 0.5 -1];
%      [centers,radii] = fcn_geometry_circleCenterFrom3Points(points,1)
% 
% See the script: script_test_fcn_Transform_CalculateAngleBetweenVectors
% for a full test suite.
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
    if ~isstruct(rawDataStructure)
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

time_range = fcn_TimeClean_FindMaxAndMinTime(rawDataStructure);
sensorfields = fieldnames(rawDataStructure);
trimedDataStructure = rawDataStructure;
for idx_field = 1:length(sensorfields)
    current_field_struct = rawDataStructure.(sensorfields{idx_field});
    trimmed_field_struct = current_field_struct;
    current_field_struct_ROS_Time = current_field_struct.ROS_Time;
    
    current_field_centiSeconds = current_field_struct.trimedDataStructure.centiSeconds;
    sample_time = current_field_centiSeconds/100;
    delta_ROS_Time = diff(current_field_struct_ROS_Time);
    ROS_Time_diff_with_sample_time = [0, delta_ROS_Time - sample_time];
    gap_idxs = (abs(ROS_Time_diff_with_sample_time)>= 0.1*sample_time);
    current_field_struct_ROS_Time(gap_idxs,:) = nan; 
    topicfields = fieldnames(current_field_struct);
    N_topics = length(topicfields);
    for idx_topic = 1:N_topics
        current_topic_content = current_field_struct.(topicfields{idx_topic});
        if length(current_topic_content) > 1
           trimmed_field_struct.(topicfields{idx_topic}) = current_topic_content(valid_idxs,:);
        end
        trimmed_field_struct.centiSeconds = current_field_struct.centiSeconds;
        trimmed_field_struct.Npoints = length(trimmed_field_struct.ROS_Time);

    end
    trimedDataStructure.(sensorfields{idx_field}) = trimmed_field_struct;

end
end
