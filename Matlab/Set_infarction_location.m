%%
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/Matlab/NIfTI image processing/');
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/Matlab/iso2mesh');
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/Matlab/functions');
load('patient_list.mat')
%%
% patient_class: "ucsd_bivent", patient_num = 1~17
% patient_class: "ucsd_ccta", patient_num = 1
% patient_class: "ucsd_lvad", patient_num = 1
% patient_class: "ucsd_pv", patient_num = 1~19
% patient_class: "ucsd_siemens", patient_num = 1~11
% patient_class: "ucsd_tavr_1", patient_num = 1~24
% patient_class: "ucsd_toshiba", patient_num = 1~21
clear point_list
patient_num = 11;
patient_class = "ucsd_siemens";
[p_class,p_id] = find_patient(patient_list,patient_class,patient_num);
fr = 0;
image_name = ['/Volumes/McVeighLab/projects/Zhennong/AI/AI_datasets/',p_class,'/',p_id,'/seg-nii/',num2str(fr),'.nii.gz'];

info.tf = 20; %number of time frames to systole
info.iso_res = 0.5; %Isotropic resolution for rotation (prior to rotation)
% get patient_specific rotation angle
angle_file_name = ['/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/angle_info/',p_class,'_',p_id,'_angle.mat'];
load(angle_file_name);
info.th_rot_z = th_rot_z;
info.th_rot_x = th_rot_x;
%
clear I
print = 1; %flag for generating a slice of the image

Reading_image_size = 5;
[I,final_limit] = Reading_Image(image_name,info,print,Reading_image_size);

disp('Done Prepping Image');
close all
info.downsampling = 0; %flag for downsampling
xmax = final_limit(1);xmin = final_limit(2);
ymax = final_limit(3);ymin = final_limit(4);
zmax = final_limit(5);zmin = final_limit(6);
% set x_lim = [min(x)/0 max(x)] in the mesh
if info.downsampling
    info.res = 2; %Desired resolution for meshes
    info.x_lim = xmax*(2/info.res); info.y_lim = ymax*(2/info.res); info.z_lim = zmax*(2/info.res); 
else
    info.res = info.iso_res;
    info.x_lim = ymax; info.y_lim = zmax; info.z_lim = xmax;
    
end

% Smoothing parameters
smoothing.switch = 1;
smoothing.iter = linspace(0,4,info.tf);
smoothing.alpha = linspace(0,0.4,info.tf);
smoothing.method = 'lowpass';
% Extracting mesh
print = 1;
info.mesh_thresh = 0.5; %Threshold for cleaning up post runnning the averaging filter

[fv,fig] = Mesh_Extraction2(I,info,print);

disp('Done Extracting the mesh');
%close all
clear print
%
datacursormode on
dcm_obj = datacursormode(fig);
count = 1;
point_list = [];
while count < 9 
% Set update function
set(dcm_obj,'UpdateFcn',@myupdatefcn)
% Wait while the user to click
disp('Click line to display a data tip, then press "Return"')
pause 
% Export cursor to workspace
info_struct = getCursorInfo(dcm_obj);
if isfield(info_struct, 'Position')
  disp('Clicked positioin is')
  disp(info_struct.Position)
  point_list = [point_list ; info_struct.Position(1) info_struct.Position(2) info_struct.Position(3)];
end
count = count + 1;
end
save(['/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/infarct_location_info/',p_class,'_',p_id,'_infarct_location','.mat'],'point_list')
save(['/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/reading_image_info/',p_class,'_',p_id,'_read','.mat'],'Reading_image_size')
close all