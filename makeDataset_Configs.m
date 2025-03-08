clearvars;

CWDataset_Configs = {
    %AntennaNum, truthvalue, filename, shift
    1, 0, 'dataset_cwsingnal/case1.mat', 10232;
    2, 60, 'dataset_cwsingnal/case2.mat', 5957;
    3, 120, 'dataset_cwsingnal/case3.mat', 1700; 
    4, 180, 'dataset_cwsingnal/case4.mat', 8361;
    5, 240, 'dataset_cwsingnal/case5.mat', 10538;
    6, 300, 'dataset_cwsingnal/case6.mat', 1015;
};

DroneDataset_Configs = {
    1, 0, 'dataset_2.455GHz/case1.mat', 68800;
    2, 60, 'dataset_2.455GHz/case2.mat', 4627;
    3, 120, 'dataset_2.455GHz/case3.mat', 12577;
    4, 180, 'dataset_2.455GHz/case4.mat', 53718;
    5, 240, 'dataset_2.455GHz/case5.mat', 11982;
    6, 300, 'dataset_2.455GHz/case6.mat', 36184;
};

save('CWDataset_Configs.mat', 'CWDataset_Configs');
save('DroneDataset_Configs.mat', 'DroneDataset_Configs');