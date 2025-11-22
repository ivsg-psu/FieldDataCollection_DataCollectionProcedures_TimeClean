function [checked_flags,sensors_without_Trigger_Time] = fcn_TimeClean_checkAllSensorsHaveTriggerTime(dataStructure,flags,varargin)

% fcn_TimeClean_checkAllSensorsHaveTriggerTime
% Check whether all sensors have Trigger Time
%
% FORMAT:
%
%      [checked_flags,sensors_without_Trigger_Time] = fcn_TimeClean_checkAllSensorsHaveTriggerTime(dataStructure,fid,flags)
%
% INPUTS:
%
%      dataStructure: a data structure to be analyzed that includes the following
%      fields:
%
%      flags: A structure 'flags' with subfield flags which are set so
%      that the flag = 1 condition represents data that passes that particular
%      consistency test.
%
%      (OPTIONAL INPUTS)
%
%      fid: a file ID to print results of analysis. If not entered, the
%      console (FID = 1) is used.
%
% OUTPUTS:
%
%      checked_flags: A structure 'flags' with field
%      Trigger_Time_exists_in_all_sensors added
%
%      sensors_without_Trigger_Time: A string array containing sensor neams
%      without Trigger_Time
%
% DEPENDENCIES:
%
%
% EXAMPLES:
%
%     See the script: script_test_fcn_TimeClean_checkAllSensorsHaveTriggerTime
%     for a full test suite.
%
% This function was written on 2024_09_03 by X.Cao
% Questions or comments? xfc5113@psu.edu

% Revision history:
%     
% 2024_09_03: xfc5113@psu.edu
% -- wrote the code originally 
% 2024_09_27: xfc5113@psu.edu
% -- add comments for the function
% 2024_09_28 - S. Brennan
% -- fixed header, function isn't working because debug flag not set right
% -- added verbose warning option
% -- changed code to avoid try/get flag setting
% -- fixed checked_flags, it was not being set with updated values


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
if (0==flag_max_speed)
    if flag_check_inputs
        % Are there the right number of inputs?
        narginchk(2,3);
    end
end
        

% Does the user want to specify the fid?
% Check for user input
fid = 0; %#ok<NASGU> % Default case is to NOT print to the console
if (0==flag_max_speed)
    if 3 == nargin
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
end

flag_do_plots = 0; % Nothing to plot

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
fields = fieldnames(dataStructure);
Nsensors = length(fields);
checked_flags = flags;


% Loop through all the sensors, checking each for trigger times
flags_thisSensorHasTriggerTime = ones(Nsensors,1);
for idx_field = 1:Nsensors
    current_field_struct = dataStructure.(fields{idx_field});
    if ~isempty(current_field_struct)
        if isfield(current_field_struct,'Trigger_Time')
            Trigger_Time = current_field_struct.Trigger_Time;
        else
            warning('on','backtrace');
            warning("%s does not have Trigger_Time field", fields{idx_field});
            flags_thisSensorHasTriggerTime(idx_field,1) = 0;
        end
    end
    if all(isnan(Trigger_Time))
        flags_thisSensorHasTriggerTime(idx_field,1) = 0;
    end

end

% Save outputs
badSensorIndicies = find(flags_thisSensorHasTriggerTime==0);

Trigger_Time_exists_in_all_sensors = 1;
sensors_without_Trigger_Time = [];
if ~isempty(badSensorIndicies)
    Trigger_Time_exists_in_all_sensors = 0;
    sensors_without_Trigger_Time = string(fields(badSensorIndicies));

end
checked_flags.Trigger_Time_exists_in_all_sensors = Trigger_Time_exists_in_all_sensors;




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

