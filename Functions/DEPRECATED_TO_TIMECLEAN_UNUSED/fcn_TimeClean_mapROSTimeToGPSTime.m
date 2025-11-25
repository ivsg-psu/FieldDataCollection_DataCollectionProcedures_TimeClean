function trimmed_dataStructure = fcn_TimeClean_mapROSTimeToGPSTime(dataStructure,varargin)

% fcn_TimeClean_mapROSTimeToGPSTime
% Trims all sensor data so that all start and end at the same GPS_Time
% values.
%
% The method this is done is to:
% 1. Pull out the GPS_Time field from all GPS-tagged sensors
% 2. Find the start/end values for each. Take the maximum start time and
%    minimum end time and assign these to the global start and end times.
% 3. Crop all data in all sensors to these global start and end times
%
% FORMAT:
%
%      trimmed_dataStructure = fcn_TimeClean_mapROSTimeToGPSTime(dataStructure,(fid))
%
% INPUTS:
%
%      dataStructure: a data structure to be analyzed that includes the following
%      fields:
%
%      (OPTIONAL INPUTS)
%
%      fid: a file ID to print results of analysis. If not entered, the
%      console (FID = 1) is used.
%
% OUTPUTS:
%
%      trimmed_dataStructure: a data structure to be analyzed that includes the following
%      fields:
% 
% DEPENDENCIES:
%
%      fcn_DebugTools_checkInputsToFunctions
%
% EXAMPLES:
%
%     See the script: script_test_fcn_TimeClean_mapROSTimeToGPSTime
%     for a full test suite.
%
% This function was written on 2023_06_19 by S. Brennan
% Questions or comments? sbrennan@psu.edu 

% Revision history:
%     
% 2023_06_12: sbrennan@psu.edu
% - Wrote the code originally 
% 
% 2023_06_24 - sbrennan@psu.edu
% - Added fcn_INTERNAL_checkIfFieldInAnySensor and test case in script
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - Changed in-use function name
%   % * From: fcn_LoadRawDataTo+MATLAB_pullDataFromFieldAcrossAllSensors
%   % * To: fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll


% TO DO
% -- As of 2023_06_25, Finish header comments for every flag


% Set default fid (file ID) first:
fid = 1; % Default case is to print to the console
flag_do_debug = 1;  %#ok<NASGU> % Flag to show the results for debugging
flag_do_plots = 0;  % % Flag to plot the final results
flag_check_inputs = 1; % Flag to perform input checking

if fid~=0
    st = dbstack; %#ok<*UNRCH>
    fprintf(fid,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
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

if flag_check_inputs
    % Are there the right number of inputs?
    if nargin < 1 || nargin > 2
        error('Incorrect number of input arguments')
    end
        
end


% Does the user want to specify the fid?

% Check for user input
if 1 <= nargin
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
% 1. Pull out the GPS_Time field from all GPS-tagged sensors
% 2. Find the start/end values for each. Take the maximum start time and
%    minimum end time and assign these to the global start and end times.
% 3. Crop all data in all sensors to these global start and end times

%% Step 1: Pull out the GPS_Time field from all GPS-tagged sensors

% Initialize arrays storing centiSeconds, start_times, and end_times across
% all sensors
sensor_centiSeconds = [];
start_times_centiSeconds = [];
end_times_centiSeconds = [];
GPS_names = {};

% Produce a list of all the sensors (each is a field in the structure)
[~,sensor_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(dataStructure, 'GPS_Time','GPS');


if 0~=fid
    fprintf(fid,'Checking consistency of start and end times across GPS sensors:\n');
end

% Loop through the fields, searching for ones that have "GPS" in their name
for i_data = 1:length(sensor_names)
    % Grab the sensor subfield name
    sensor_name = sensor_names{i_data};
    sensor_data = dataStructure.(sensor_name);
    
    if 0~=fid
        fprintf(fid,'\t Checking sensor %d of %d: %s\n',i_data,length(sensor_names),sensor_name);
    end
    
    times_centiSeconds = round(100*sensor_data.GPS_Time/sensor_data.centiSeconds)*sensor_data.centiSeconds;
    sensor_centiSeconds = [sensor_centiSeconds; sensor_data.centiSeconds]; %#ok<AGROW>
    start_times_centiSeconds = [start_times_centiSeconds; times_centiSeconds(1)]; %#ok<AGROW>
    end_times_centiSeconds = [end_times_centiSeconds; times_centiSeconds(end)]; %#ok<AGROW>
    GPS_names{end+1} = sensor_name; %#ok<AGROW>
end


%% Step 2. Find the start/end values for each
% Take the maximum start time and minimum end time and assign these to the
% global start and end times.
master_start_time_centiSeconds = max(start_times_centiSeconds);
master_end_time_centiSeconds = min(end_times_centiSeconds);

% Make sure we choose a time that all the sensors CAN start at. We round
% start seconds up, and end seconds down.
master_start_time_Seconds = ceil(master_start_time_centiSeconds*0.01);
master_end_time_Seconds = floor(master_end_time_centiSeconds*0.01);

% THE COMMENTED AREA BELOW DOES A MORE REFINED CALCULATION
% % Make sure we choose a time that all the sensors CAN start at. For
% % example, if one sensor is 10Hz and another is 20 Hz, we cannot use 3.05
% % seconds as a start time because only the 20Hz sensor lands on this. We
% % have to find a start time that they all land on, for example 3.10 seconds.
% loop_iterations = 1;
% while ~all(mod(master_start_time_centiSeconds,sensor_centiSeconds)==0)
%     loop_iterations = loop_iterations+1;
%     master_start_time_centiSeconds = master_start_time_centiSeconds + min(sensor_centiSeconds);
%     if loop_iterations>100
%         error('Unable to lock GPS signals to a common start time');
%     end
% end
% 
% loop_iterations = 1;
% while ~all(mod(master_end_time_centiSeconds,sensor_centiSeconds)==0)
%     loop_iterations = loop_iterations+1;
%     master_end_time_centiSeconds = master_end_time_centiSeconds - min(sensor_centiSeconds);
%     if loop_iterations>100
%         error('Unable to lock GPS signals to a common end time');
%     end
% end
% 
% % Convert back into normal seconds
% master_start_time_Seconds = master_start_time_centiSeconds*0.01;
% master_end_time_Seconds = master_end_time_centiSeconds*0.01;

if master_start_time_Seconds>=master_end_time_Seconds
    warning('on','backtrace');
    warning('\n\nAn error will be thrown due to bad GPS timings. The following table should assist in debugging this issue: \n');
    fprintf('Sensor \t\t\t\t Start time: \t End_time\n');    
    for ith_sensor = 1:length(start_times_centiSeconds)
        fprintf('%s \t %d  \t %d \n',GPS_names{ith_sensor}, start_times_centiSeconds(ith_sensor),end_times_centiSeconds(ith_sensor));        
    end
    
    fprintf('Master start time (seconds): \t%d\n',master_start_time_Seconds);
    fprintf('Master end time (seconds):   \t%d\n',master_end_time_Seconds);
    
    fprintf('\n\nTable reshifted by start time:\n');
    fprintf('Sensor \t\t\t\t Start time: \t End_time\n');
    for ith_sensor = 1:length(start_times_centiSeconds)
        fprintf('%s \t %d  \t %d \n',GPS_names{ith_sensor}, start_times_centiSeconds(ith_sensor)-master_start_time_Seconds*100,end_times_centiSeconds(ith_sensor)-master_start_time_Seconds*100);        
    end

        
    fprintf('\n\nEach sensor shifted by its own start time:\n');
    fprintf('Sensor \t\t\t\t Start time: \t End_time\n');
    for ith_sensor = 1:length(start_times_centiSeconds)
        fprintf('%s \t %d  \t %d \n',...
            GPS_names{ith_sensor}, ...
            start_times_centiSeconds(ith_sensor)-start_times_centiSeconds(ith_sensor),...
            end_times_centiSeconds(ith_sensor)-start_times_centiSeconds(ith_sensor));        
    end
    
    error('Unable to synchronize GPS signals because one GPS sensor has a starting GPS_Time field that seems to "start" after another GPS sensor recording ended! This is not physically possible if the sensors are running at the same time.');
end

fprintf(fid,'\t The GPS_Time that overlaps all sensors has the following range: \n');
fprintf(fid,'\t\t Start Time (UTC seconds): %.3f\n',master_start_time_Seconds);
fprintf(fid,'\t\t End Time   (UTC seconds): %.3f\n',master_end_time_Seconds);


%% Step 3: Trim all data to common start/end times

% Initialize the result:
trimmed_dataStructure = dataStructure;

% Loop through the fields, searching for ones that have "GPS" in their name
for i_data = 1:length(sensor_names)
    % Grab the sensor subfield name
    sensor_name = sensor_names{i_data};
    sensor_data = dataStructure.(sensor_name);
    
    if 0~=fid
        fprintf(fid,'\t Trimming sensor %d of %d to have correct start and end GPS_Time values: %s\n',i_data,length(sensor_names),sensor_name);
    end
    
    start_index = find(sensor_data.GPS_Time >= master_start_time_Seconds,1);
    end_index   = find(sensor_data.GPS_Time <= master_end_time_Seconds, 1, 'last');
    lengthReference = length(sensor_data.GPS_Time);

    % Loop through subfields
    subfieldNames = fieldnames(sensor_data);
    for i_subField = 1:length(subfieldNames)
        % Grab the name of the ith subfield
        subFieldName = subfieldNames{i_subField};
        
        if ~iscell(dataStructure.(sensor_name).(subFieldName)) % Is it a cell? If yes, skip it
            if length(dataStructure.(sensor_name).(subFieldName)) ~= 1 % Is it a scalar? If yes, skip it
                % It's an array, make sure it has right length
                if lengthReference~= length(dataStructure.(sensor_name).(subFieldName))
                    if strcmp(sensor_name,'SickLiDAR') && strcmp(subFieldName,'Sick_Time')
                        warning('on','backtrace');
                        warning('SICK lidar has a time vector that does not match data arrays. This will make this data unusable.');
                    else
                        warning('on','backtrace');
                        warning('A datafield error was encountered.')
                        error('Sensor %s contains a datafield %s that has an amount of data not equal to the GPS_Time. This is usually because data is missing.',sensor_name,subFieldName);
                    end
                end
                
                % Replace the values
                trimmed_dataStructure.(sensor_name).(subFieldName) = dataStructure.(sensor_name).(subFieldName)(start_index:end_index,:);
            end
        end
       
    end % Ends for loop through the subfields
    
    
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

