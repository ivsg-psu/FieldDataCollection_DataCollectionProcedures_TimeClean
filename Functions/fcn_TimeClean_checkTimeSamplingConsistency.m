function [flags,offending_sensor,return_flag] = fcn_TimeClean_checkTimeSamplingConsistency(dataStructure, field_name, verificationTypeFlag, varargin)
% fcn_TimeClean_checkTimeSamplingConsistency Checks to see if the sensor's
% measured sampling time, when rounded to the desired samping interval in
% centiSeconds, matches the desired sampling time. Basically, if a sensor
% is set to measure every 10 centiSeconds, this checks that indeed data
% appears to be measured every 10 centiSeconds.
%
% FORMAT:
%
%      [flags,offending_sensor] = fcn_TimeClean_checkTimeSamplingConsistency(...
%          dataStructure, field_name, verificationTypeFlag, ...
%          (flags), (sensors_to_check), (fid), (figNum))
%
% INPUTS:
%
%      dataStructure: a data structure to be analyzed
%
%      field_name: the field to be checked
%
%      verificationTypeFlag: a flag that checks the verification type. The
%      following types are allowed:
%
%            0: mode matching - the code calculates the sampling itervals,
%               rounds them to the nearest centiSecond, and finds the most
%               common result (the mode of the data). The flag passes if
%               the mode matches the centiSecond setting. This method is
%               useful to check that the centiSeconds is set correctly.
%               (default)
%
%            1: interval matching - the code calculates the sampling
%               intervals and divides every result by the expected sampling
%               interval calculated from the intended centiSeconds. It then
%               rounds to the nearest integer. To pass, all observed
%               sampling intervals must round to 1. This method is useful
%               to catch if all the data are correctly sampled.
%
%            2: count matching - the code calculated the number of expected
%               samples based on the centiSeconds. This method is useful to
%               check that the amount of data agrees with expected amounts.
%
%      (OPTIONAL INPUTS)
%
%      flags: If a structure is entered, it will append the flag result
%      into the structure to allow a pass-through of flags structure
%
%      sensors_to_check: a string listing the sensors to check. For
%      example, 'GPS' will check every sensor in the dataStructure whose
%      name contains 'GPS'. Default is empty, which checks all sensors.
%
%      fid: a file ID to print results of analysis. If not entered, no
%      output is given (FID = 0). Set fid to 1 for printing to console.
%
%      figNum: a figure number to plot results. If set to -1, skips any
%      input checking or debugging, no figures will be generated, and sets
%      up code to maximize speed.
%
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
%     See the script: script_test_fcn_TimeClean_checkTimeSamplingConsistency
%     for a full test suite.
%
% This function was written on 2023_07_01 by S. Brennan
% Questions or comments? sbrennan@psu.edu 

% REVISION HISTORY:
%     
% 2023_07_01 by Sean Brennan, sbrennan@psu.edu
% - Wrote the code originally 
% 
% 2024_09_29 by Sean Brennan, sbrennan@psu.edu
% - Updated top comments
% - Added debug flag area
% - Added figNum input, fixed the plot flag
% - Fixed warning and errors
% 
% 2024_11_10 by Sean Brennan, sbrennan@psu.edu
% - Updated plotting
% - Updated calculation of consistency to match values where the data
%    would round
% - Updated debugging outputs
% - Added verificationTypeFlag
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - Changed in-use function name
%   % * From: fcn_LoadRawDataTo+MATLAB_pullDataFromFieldAcrossAllSensors
%   % * To: fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll
% - Fixed printing bugs where errors thrown

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)



%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the figNum variable input
% argument (varargin) is given a number of -1, which is not a valid figure
% number.
flag_max_speed = 0;
if (nargin==7 && isequal(varargin{end},-1))
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
        narginchk(3,7);
    end
end

% Does the user specify verificationTypeFlag?
if isempty(verificationTypeFlag)
    verificationTypeFlag = 0;
end

% Does the user want to specify the flags?
flags = struct;
if 4 <= nargin
    temp = varargin{1};
    if ~isempty(temp)
        flags = temp;
    end
end

% Does the user want to specify the sensors_to_check?
sensors_to_check = '';
if 5 <= nargin
    temp = varargin{2};
    if ~isempty(temp)
        sensors_to_check = temp;
    end
end


% Does the user want to specify the fid?
fid = 0;
if (0==flag_max_speed)
    % Check for user input
    if 6 <= nargin
        temp = varargin{3};
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
if (0==flag_max_speed) &&  (7<=nargin)
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

if isempty(sensors_to_check)
    flag_check_all_sensors = 1;    
else
    flag_check_all_sensors = 0;
end

% Set up the field name
if 0==verificationTypeFlag
    flagNameFront = '_sample_modes_match_centiSeconds';
elseif 1==verificationTypeFlag
    flagNameFront = '_sampling_matches_centiSeconds';
elseif 2==verificationTypeFlag
    flagNameFront = '_sample_counts_match_centiSeconds';
else
    warning('on','backtrace');
    warning('An unexpected verification type encountered. Must throw error');
    error('Unknown verificationTypeFlag encountered: %.0f',verificationTypeFlag);
end

if flag_check_all_sensors
    flag_name = cat(2,field_name,flagNameFront);
else
    flag_name = cat(2,field_name,flagNameFront,sprintf('_in_%s_sensors',sensors_to_check));
end

% Initialize offending_sensor
offending_sensor = '';
return_flag = 0;

% Produce a list of all the sensors (each is a field in the structure)
if flag_check_all_sensors
    sensor_names = fieldnames(dataStructure); % Grab all the fields that are in dataStructure structure
else
    % Produce a list of all the sensors that meet the search criteria, and grab
    % their data also
    [~,sensor_names] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAll(dataStructure, field_name,sensors_to_check);
end


if 0~=fid
    fprintf(fid,'Checking consistency of expected and actual time sampling rates of ''%s''',field_name);
    if flag_check_all_sensors
        fprintf(fid,': --> %s\n', flag_name);
    else
        fprintf(fid,' in all %s sensors: --> %s\n', sensors_to_check, flag_name);
    end
end

Ndata = length(sensor_names);

allTimeDifferences = cell(Ndata,1);
for i_data = 1:Ndata
    
    % Grab the sensor subfield name
    sensor_name = sensor_names{i_data};
    sensor_data = dataStructure.(sensor_name);
    
    if 0~=fid
        fprintf(fid,'\t Checking sensor %d of %d: %s\n',i_data,length(sensor_names),sensor_name);
    end
    
    centiSeconds = sensor_data.centiSeconds(1);

    % Calculate the time differences. Repeat the last one so that the
    % differences match the data length
    timeData = sensor_data.(field_name);
    timeDifferences = diff(timeData);
    timeDifferences = [timeDifferences; timeDifferences(end)]; %#ok<AGROW>
    allTimeDifferences{i_data,1} = timeDifferences;

    % From the time differences, determine where they would round. This is
    % done by calculating the sampling intervals and dividing by the expected sampling
    % interval calculated from the intended centiSeconds. To pass, all
    % values must round to 1.

    % If the data is correct, then the rounding operation in the next line
    % will always produce a value of 1
    effectiveSamplingIntervals = round(timeDifferences*100/centiSeconds);

    % NOTE: the rounding operation above will still produce 1 values if the
    % sampling rate is systematically off, say 6 centiSeconds instead of 5.
    % Need to also check that the expected number of samples is there.
    expectedNsamples = round((max(timeData) - min(timeData))/(0.01*centiSeconds))+1;

    % Find indicies of any situations that are NOT 1, these are errors
    indiciesOfBadIntervals = find(1~=effectiveSamplingIntervals);

    % Find the time sampling interval that occurs most often, in
    % centiSeconds
    [modeInterval, modeCount] = mode(round(timeDifferences*100));

    % Based on verificationTypeFlag, check to see if flag passes
    if 0==verificationTypeFlag
        if modeInterval==centiSeconds
            flags_dataTimeIntervalMatchesIntendedSamplingRate = 1;
        else
            flags_dataTimeIntervalMatchesIntendedSamplingRate = 0;
        end
    elseif 1==verificationTypeFlag
        if isempty(indiciesOfBadIntervals) 
            flags_dataTimeIntervalMatchesIntendedSamplingRate = 1;
        else
            flags_dataTimeIntervalMatchesIntendedSamplingRate = 0;
        end
    elseif 2==verificationTypeFlag
        if length(timeData)==expectedNsamples
            flags_dataTimeIntervalMatchesIntendedSamplingRate = 1;
        else
            flags_dataTimeIntervalMatchesIntendedSamplingRate = 0;
        end

    else
        error('Unknown verificationTypeFlag encountered: %.0f',verificationTypeFlag);
    end


       

    if 0==return_flag && ~flags_dataTimeIntervalMatchesIntendedSamplingRate
        return_flag = 1; % Indicate that the return was forced
    end

    if 0==flags_dataTimeIntervalMatchesIntendedSamplingRate
        if isempty(offending_sensor)
            offending_sensor = sensor_name;
        else
            offending_sensor = cat(2,offending_sensor,' ',sensor_name); % Save the name of the sensor
        end
        NbadIntervals = length(indiciesOfBadIntervals);
        ratioBadIntervals = NbadIntervals/length(timeDifferences);
        maxInterval = max(timeDifferences);
        minInterval = min(timeDifferences);
        meanInterval = mean(timeDifferences);

        if 0~=fid
            fprintf(fid,'\t\t Sensor failed!\n');
            fprintf(fid,'\t\t Sensor had %.0f errors (out of %.0f intervals), or %.0f percent.\n',NbadIntervals,length(timeDifferences), ratioBadIntervals*100);
            fprintf(fid,'\t\t Mean interval: %.5f seconds.\n',meanInterval);
            fprintf(fid,'\t\t Max interval:  %.5f seconds.\n',maxInterval);
            fprintf(fid,'\t\t Min interval:  %.5f seconds.\n',minInterval);
            fprintf(fid,'\t\t Mode interval: %.0f centiSeconds at a frequency of %.0f (out of %.0f intervals, or %.0f percent)\n',...
                modeInterval, modeCount, length(timeDifferences), modeCount/length(timeDifferences)*100);
            fprintf(fid,'\t\t Expected interval:  %.0f centiseconds.\n',centiSeconds);
            fprintf(fid,'\t\t Expected number of samples:  %.0f.\n',expectedNsamples);
            fprintf(fid,'\t\t Actual number of samples:    %.0f.\n',length(timeData));

            if ~isempty(indiciesOfBadIntervals)
                bad_index = indiciesOfBadIntervals(1);
                indexRange = 10;
                start_print = max(bad_index-indexRange,1);
                end_print = min(bad_index+indexRange,length(timeDifferences(:,1)));
                if isfield(sensor_data,'Trigger_Time')
                    timeLabelString = 'Trigger_Time';
                    temp = [sensor_data.Trigger_Time timeData  timeDifferences effectiveSamplingIntervals];
                elseif isfield(sensor_data,'GPS_Time')
                    timeLabelString = 'GPS_Time';
                    temp = [sensor_data.GPS_Time timeData  timeDifferences effectiveSamplingIntervals];
                end
                fprintf(1,'\t\tExample of failure:\n')
                fprintf(1,'\t\t\t (%s) \t (%s) \t (timeDifferences) \t (effectiveSamplingIntervals)\n',timeLabelString, field_name)
                for ith_index = start_print:end_print
                    if ith_index~=bad_index
                        fprintf(1,'\t\t\t %.4f \t %.4f \t %.4f \t\t\t %.0f\n',temp(ith_index,1),temp(ith_index,2),temp(ith_index,3),temp(ith_index,4))
                    else
                        fcn_DebugTools_cprintf('Red','\t\t\t %.4f \t %.4f \t %.4f \t\t\t %.0f\n',temp(ith_index,1), temp(ith_index,2),temp(ith_index,3),temp(ith_index,4))
                    end
                end
            end
        else
            % Throw warnings on catastrophic errors that are not fixable
            if 0==verificationTypeFlag
                warning('on','backtrace');
                warning(['The sensor: %s has a catastrophic sampling interval error.\n' ...
                    '\t Expecting a sample rate (from centiSeconds): %.4f seconds.\n' ...
                    '\t Mode sampling interval:                      %.4f seconds\n',...
                    '\t           Mode count: %.0f (out of %.0f intervals, or %.0f percent wrong)\n',...
                    '\t Effective sampling interval, average:        %.4f seconds\n',...
                    '\t Percentage with an incorrect sample intervals: %.0f percent wrong.\n' ...
                    '\t The total number of bad intervals: %.0f of %.0f\n' ...
                    '\t The maximum time sampling interval: %.5f seconds\n' ...
                    '\t The minimum time sampling interval: %.5f seconds\n'],...
                    sensor_name,...
                    centiSeconds*0.01,...
                    modeInterval*0.01,...
                    modeCount, length(timeDifferences), modeCount/length(timeDifferences)*100,...
                    meanInterval,...
                    ratioBadIntervals*100,...
                    NbadIntervals,length(timeDifferences),...
                    maxInterval,...
                    minInterval);
            end
        end
    end

end

if 0==return_flag
    flags.(flag_name) = 1;
else
    flags.(flag_name) = 0;
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

% Does this need to be plotted, and is figure NOT open already?
if flag_do_plots && 1==verificationTypeFlag && isempty(findobj('Number',figNum))

    figure(figNum);
    % set(figNum,'WindowState','maximized');

    
    % check whether the figure already has data
    % temp_h = figure(figNum); 
    % flag_rescale_axis = 0;
    % if isempty(get(temp_h,'Children'))
    %     flag_rescale_axis = 1;
    % end

    tiledlayout('flow')

    for i_data = 1:Ndata
        nexttile

        % make plots
        data = allTimeDifferences{i_data,1};
        histogram(data*100,100,'Normalization','percentage');
        
        title(sprintf('%s',sensor_names{i_data}),'Interpreter','none');
        xlabel('Sampling Interval (centiSeconds)');
        ylabel('Percentage');
    end

    %% Plot GPS locations

    % Test the function
    clear plotFormat

    plotFormat.Color = [0 0.7 0];
    plotFormat.Marker = '.';
    plotFormat.MarkerSize = 10;
    plotFormat.LineStyle = 'none';
    plotFormat.LineWidth = 3;

    % Does user want to specify colorMapToUse?
    % Fill in large colormap data using turbo
    colorMapMatrix = colormap('turbo');
    colorMapMatrix = colorMapMatrix(100:end,:); % Keep the scale from green to red
    % Reduce the colormap
    Ncolors = 20;
    colorMapToUse = fcn_plotRoad_reduceColorMap(colorMapMatrix, Ncolors, -1);

    % Is this a GPS sensor
    GPS_indicies = find(contains(sensor_names,'GPS'));
    GPS_sensor_names = cell(length(GPS_indicies),1);
    for ith_sensor = 1:length(GPS_indicies)
        GPS_sensor_names{ith_sensor} = sensor_names{GPS_indicies(ith_sensor)}; 
    end

    % legend_entries = GPS_sensor_names;
    for ith_sensor = 1:length(GPS_sensor_names)

        nexttile

        % Grab the sensor subfield name
        sensor_name = GPS_sensor_names{ith_sensor};
        sensor_data = dataStructure.(sensor_name);

        LLdata = [sensor_data.Latitude sensor_data.Longitude];

        % Convert LLA to ENU
        reference_latitude = 40.86368573;
        reference_longitude = -77.83592832;
        reference_altitude = 344.189;
        MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE = getenv("MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE");
        MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE = getenv("MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE");
        MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE = getenv("MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE");
        if ~isempty(MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE) && ~isempty(MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE) && ~isempty(MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE)
            reference_latitude  = str2double(MATLABFLAG_PLOTROAD_REFERENCE_LATITUDE);
            reference_longitude = str2double(MATLABFLAG_PLOTROAD_REFERENCE_LONGITUDE);
            reference_altitude  = str2double(MATLABFLAG_PLOTROAD_REFERENCE_ALTITUDE);
        end
        gps_object = GPS(reference_latitude,reference_longitude,reference_altitude); % Load the GPS class
        ENU_coordinates = gps_object.WGSLLA2ENU(LLdata(:,1),LLdata(:,2),reference_altitude*ones(length(LLdata(:,1)),1),reference_latitude,reference_longitude,reference_altitude);

        
        if 1==0
            % Plot all the points with time errors
            NdataThisSensor = length(allTimeDifferences{ith_sensor,1}(:,1));
            Idata = 0.1*ones(NdataThisSensor,1);
            Idata(round(allTimeDifferences{ith_sensor,1}*100)>centiSeconds) = 0.9;
        else
            searchRadiusAndAngles = 10;

            [~, Nnearby]  = fcn_TimeClean_findNearPoints(ENU_coordinates, searchRadiusAndAngles, (-1));

            bad_Indicies = find(round(allTimeDifferences{ith_sensor,1}*100)>centiSeconds);
            ENU_badData = ENU_coordinates(bad_Indicies,1:2); %#ok<FNDSB>
            Npoints = length(ENU_coordinates(:,1));
            NbadNearby = nan(Npoints,1);
            for ith_point = 1:Npoints
                this_point = ENU_coordinates(ith_point,1:2);
                distances = sum((this_point - ENU_badData).^2,2).^0.5;
                NbadNearby(ith_point,1) = sum(distances<=searchRadiusAndAngles);
            end
            
            Idata = max(NbadNearby,0)./max(Nnearby,1);

        end


        fcn_plotRoad_plotLLI([LLdata Idata], (plotFormat), colorMapToUse, (figNum));

        % h_legend = legend(legend_entries);
        % set(h_legend,'Interpreter','none','FontSize',6)

        % Force the plot to fit
        geolimits('auto');
        title(sprintf('%s errors for %s',field_name, sensor_name),'interpreter','none','FontSize',12)
        cb = colorbar();
        ylabel(cb,'% drop in last 1 second')
    end

    if flag_check_all_sensors
        sgtitle(sprintf('Checking Time Sampling Consistency for field: %s, among all sensors',field_name),'interpreter','none');
    else
        sgtitle(sprintf('Checking Time Sampling Consistency for field: %s, among sensors: %s',field_name, sensors_to_check),'interpreter','none');
    end

    % % Make axis slightly larger?
    % if flag_rescale_axis
    %     temp = axis;
    %     %     temp = [min(points(:,1)) max(points(:,1)) min(points(:,2)) max(points(:,2))];
    %     axis_range_x = temp(2)-temp(1);
    %     axis_range_y = temp(4)-temp(3);
    %     percent_larger = 0.3;
    %     axis([temp(1)-percent_larger*axis_range_x, temp(2)+percent_larger*axis_range_x,  temp(3)-percent_larger*axis_range_y, temp(4)+percent_larger*axis_range_y]);
    % end
    % 
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

