%%
clear all;
%%
mainpath = '/Volumes/McVeighLab/projects/Zhennong/AI/AI_datasets/';
patient_class = ["ucsd_bivent","ucsd_ccta","ucsd_lvad","ucsd_pv","ucsd_siemens","ucsd_tavr_1","ucsd_toshiba"];

patient_list = [];
for i = 1:length(patient_class)
    B = convertStringsToChars(patient_class(i));
    classFolder = [mainpath,B];
    files = dir(classFolder);
    for j = 1:size(files,1)
        patient_name = files(j).name;
        if (patient_name(1) ~= '.')
            patient_list = [patient_list;patient_class(i),convertCharsToStrings(patient_name)];
    end
    end
end

