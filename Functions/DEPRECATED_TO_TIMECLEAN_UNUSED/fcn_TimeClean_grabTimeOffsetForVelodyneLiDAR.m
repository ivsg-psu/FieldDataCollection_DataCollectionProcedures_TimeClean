function time_offsets = fcn_TimeClean_grabTimeOffsetForVelodyneLiDAR(dataStructure)


%% Pull PointCloud Cell from Velodyne LiDAR
[cell_array_PointCloud,LiDAR_Names_PointCloud] = fcn_LoadRawDataToMATLAB_pullDataFromFieldAcrossAllSensors(dataStructure, 'PointCloud','lidar');


N_LiDAR_units = length(LiDAR_Names_PointCloud);
for idx_LiDAR = 1:N_LiDAR_units
    LiDARName = LiDAR_Names_PointCloud{idx_LiDAR};
    if strcmp(LiDARName, 'LiDAR_Velodyne_Rear')
        PointCloud_LiDARVelodyne = cell_array_PointCloud{idx_LiDAR};
    end
end

N_scans = length(PointCloud_LiDARVelodyne);
for idx_scan = 1:N_scans
    current_PointCloud = PointCloud_LiDARVelodyne{idx_scan};
    time_offsets_array = current_PointCloud(:,6);
    




end
