%% script_test_fcn_TimeClean_findNearPoints
% This is a script to exercise the function:
% fcn_TimeClean_findNearPoints.m
% This function was written on 2024_10_27 by S. Brennan, sbrennan@psu.edu
% by modifying script _ test _ fcn _ plotCV2X _ findNearPoints


% REVISION HISTORY:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - Added rev history
% - Added TO+_DO list

% TO-DO:
%
% 2025_11_24 by Sean Brennan, sbrennan@psu.edu
% - (insert items here)

%% test 1 - velocity calculation using TestTrack_PendulumRSU_InstallTest_OuterLane1_2024_08_09.csv test file
figNum = 1;
figure(figNum);
clf;

% Load the data
ENU_data =    1.0e+04 *[
  -1.094459791651575  -0.168290614833392  -0.000959908358738
  -1.094515445400136  -0.168230308176135  -0.000959987772771
  -1.094571351111617  -0.168168205859994  -0.000960067154462
  -1.094628570452868  -0.168104898594026  -0.000960148480020
  -1.094686424239538  -0.168040202288609  -0.000960230537381
  -1.094744629914429  -0.167974339453674  -0.000960312901739
  -1.094800414004277  -0.167906462766710  -0.000960390596073
  -1.094860184592643  -0.167837136620141  -0.000960474753421
  -1.094921551769555  -0.167766660633552  -0.000960561357580
  -1.094981601540256  -0.167694816966048  -0.000960645356580
  -1.095043291249751  -0.167622452670806  -0.000960732043587
  -1.095105051153835  -0.167549736613655  -0.000960818772490
  -1.095168617696453  -0.167474426776010  -0.000960907930600
  -1.095297556473640  -0.167320584034375  -0.000961088541175
  -1.095363439081671  -0.167242864741180  -0.000961181083843
  -1.095429815256632  -0.167164145282649  -0.000961274226429
  -1.095496161669328  -0.167084426423531  -0.000961367072402
  -1.095563567598039  -0.167003836128647  -0.000961461523527
  -1.095631848980530  -0.166922245109829  -0.000961557231243
  -1.095700595748577  -0.166839727998880  -0.000961653512105
  -1.095770627658666  -0.166755876418766  -0.000961751666028
  -1.095840178467462  -0.166671895978326  -0.000961848979469
  -1.095910733485339  -0.166587914063316  -0.000961948034234
  -1.095981273423253  -0.166503302887606  -0.000962046917317
  -1.096052829089433  -0.166416894933205  -0.000962147092362
  -1.096197113404194  -0.166243448011980  -0.000962349349902
  -1.096268851566566  -0.166156132872002  -0.000962449660773
  -1.096411620614095  -0.165981485097462  -0.000962649123887
  -1.096482298576172  -0.165894615681967  -0.000962747791104
  -1.096552920378988  -0.165808042471871  -0.000962846458613
  -1.096693134050189  -0.165636692824824  -0.000963042551966
  -1.096761749686067  -0.165551714227339  -0.000963138248200
  -1.096830295777638  -0.165467550082028  -0.000963234055520
  -1.096898135060814  -0.165383664586504  -0.000963328739999
  -1.096964617183293  -0.165300243773570  -0.000963421232554
  -1.097030039060967  -0.165217213176667  -0.000963512023540
  -1.097094159840364  -0.165134295526929  -0.000963600626604
  -1.097157078665282  -0.165051583220127  -0.000963687235615
  -1.097218469168486  -0.164968354917783  -0.000963771102455
  -1.097277613989087  -0.164887332363242  -0.000963851699841
  -1.097336642123844  -0.164803903919869  -0.000963931489560
  -1.097392829094856  -0.164721701166800  -0.000964006731561
  -1.097449004049372  -0.164640960568029  -0.000964082346926
  -1.097503124052918  -0.164557446756437  -0.000964153729358
  -1.097556366495045  -0.164473508539347  -0.000964223509821
  -1.097607729593184  -0.164390813113847  -0.000964290397233
  -1.097658466714705  -0.164305638514123  -0.000964355583747
  -1.097707381529507  -0.164222021261017  -0.000964418055985
  -1.097754258600502  -0.164137722188801  -0.000964476864879
  -1.097843356015350  -0.163966854357338  -0.000964585937628];

% Test the function
searchRadiusAndAngles = 20;
[nearbyIndicies, Nnearby]  = fcn_TimeClean_findNearPoints(ENU_data, searchRadiusAndAngles, (figNum));
title({sprintf('Example %.0d: showing fcn_TimeClean_findNearPoints',figNum), 'Basic test case'}, 'Interpreter','none','FontSize',12);

% Was a figure created?
assert(all(ishandle(figNum)));

% Does the data have right size?
Nrows_expected = length(ENU_data(:,1));
assert(length(nearbyIndicies(1,:))== Nrows_expected)
assert(length(Nnearby(:,1))== Nrows_expected)



 %% test 2 - collect data with no plotting
% figNum = 2;
% figure(figNum);
% close(figNum);
% 
% % Load the data
% csvFile = 'TestTrack_PendulumRSU_InstallTest_OuterLane1_2024_08_09.csv'; % Path to your CSV file
% [tLLA, tENU] = fcn_plotCV2X_loadDataFromFile(csvFile, (-1));
% 
% % Test the function
% searchRadiusAndAngles = 50;
% nearbyIndicies  = fcn_TimeClean_findNearPoints(tENU, searchRadiusAndAngles, ([]));
% title({sprintf('Example %.0d: showing fcn_TimeClean_findNearPoints',figNum), sprintf('File: %s',csvFile)}, 'Interpreter','none','FontSize',12);
% 
% % Was a figure created?
% assert(all(~ishandle(figNum)));
% 
% % Does the data have right size?
% Nrows_expected = length(tLLA(:,1));
% assert(length(nearbyIndicies(1,:))== Nrows_expected)
% 
% 
% %% test 3 - testing association by distance and angle
% 
% figNum = 1;
% figure(figNum);
% clf;
% 
% % Load the data
% csvFile = 'TestTrack_PendulumRSU_InstallTest_OuterLane1_2024_08_09.csv'; % Path to your CSV file
% [tLLA, tENU] = fcn_plotCV2X_loadDataFromFile(csvFile, (-1));
% 
% 
% % Test the function
% searchRadiusAndAngles = [500 10*pi/180];
% nearbyIndicies  = fcn_TimeClean_findNearPoints(tENU, searchRadiusAndAngles, (figNum));
% title({sprintf('Example %.0d: showing fcn_TimeClean_findNearPoints',figNum), sprintf('File: %s',csvFile)}, 'Interpreter','none','FontSize',12);
% 
% % Was a figure created?
% assert(all(ishandle(figNum)));
% 
% % Does the data have right size?
% Nrows_expected = length(tLLA(:,1));
% assert(length(nearbyIndicies(1,:))== Nrows_expected)
% 
% 
% 
% %% Speed test
% 
% % Load the data
% csvFile = 'TestTrack_PendulumRSU_InstallTest_OuterLane1_2024_08_09.csv'; % Path to your CSV file
% [tLLA, tENU] = fcn_plotCV2X_loadDataFromFile(csvFile, (-1));
% searchRadiusAndAngles = 50;
% 
% % Test the function
% figNum=[];
% REPS=5; 
% minTimeSlow=Inf;
% maxTimeSlow=-Inf;
% tic;
% 
% % Slow mode calculation - code copied from plotVehicleXYZ
% for i=1:REPS
%     tstart=tic;
%     nearbyIndicies  = fcn_TimeClean_findNearPoints(tENU, searchRadiusAndAngles, (figNum));
%     telapsed=toc(tstart);
%     minTimeSlow=min(telapsed,minTimeSlow);
%     maxTimeSlow=max(telapsed,maxTimeSlow);
% end
% averageTimeSlow=toc/REPS;
% % Slow mode END
% 
% % Fast Mode Calculation
% figNum = -1;
% minTimeFast = Inf;
% tic;
% for i=1:REPS
%     tstart = tic;
%     nearbyIndicies  = fcn_TimeClean_findNearPoints(tENU, searchRadiusAndAngles, (figNum));
%     telapsed = toc(tstart);
%     minTimeFast = min(telapsed,minTimeFast);
% end
% averageTimeFast = toc/REPS;
% % Fast mode END
% 
% % Display Console Comparison
% if 1==1
%     fprintf(1,'\n\nComparison of fcn_TimeClean_findNearPoints without speed setting (slow) and with speed setting (fast):\n');
%     fprintf(1,'N repetitions: %.0d\n',REPS);
%     fprintf(1,'Slow mode average speed per call (seconds): %.5f\n',averageTimeSlow);
%     fprintf(1,'Slow mode fastest speed over all calls (seconds): %.5f\n',minTimeSlow);
%     fprintf(1,'Fast mode average speed per call (seconds): %.5f\n',averageTimeFast);
%     fprintf(1,'Fast mode fastest speed over all calls (seconds): %.5f\n',minTimeFast);
%     fprintf(1,'Average ratio of fast mode to slow mode (unitless): %.3f\n',averageTimeSlow/averageTimeFast);
%     fprintf(1,'Fastest ratio of fast mode to slow mode (unitless): %.3f\n',maxTimeSlow/minTimeFast);
% end
% %Assertion on averageTime NOTE: Due to the variance, there is a chance that
% %the assertion will fail.
% assert(averageTimeFast<4*averageTimeSlow);
