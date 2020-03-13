%% 

addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/NIfTI image processing/');
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/iso2mesh');
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/functions');
%%
% patient_class: "ucsd_bivent", patient_num = 1~17
% patient_class: "ucsd_ccta", patient_num = 1
% patient_class: "ucsd_lvad", patient_num = 1
% patient_class: "ucsd_pv", patient_num = 1~19
% patient_class: "ucsd_siemens", patient_num = 1~11
% patient_class: "ucsd_tavr_1", patient_num = 1~24
% patient_class: "ucsd_toshiba", patient_num = 1~21
clear all
load('patient_list.mat')
patient_class = "ucsd_toshiba";
patient_num = 21; % the Patinet no. in that patient class

% get the patient_class, p_class and patient_id, p_id
[p_class,p_id] = find_patient(patient_list,patient_class,patient_num);
fr = 0;
image_name = ['/Volumes/McVeighLab/projects/Zhennong/AI/AI_datasets/',p_class,'/',p_id,'/seg-nii/',num2str(fr),'.nii.gz'];

info.tf = 20; %number of time frames to systole
info.iso_res = 0.5; %Isotropic resolution for rotation (prior to rotation)
% get patient_specific rotation angle
data = load_nii(image_name);
dx = data.hdr.dime.pixdim(2);
dy = data.hdr.dime.pixdim(3);
dz = data.hdr.dime.pixdim(4);
res = info.iso_res;
I = zeros(size(data.img));
I(data.img==1) = 1;
I = permute(I,[2 1 3]);
I = flip(I,1);
I = flip(I,2);
I = flip(I,3);
ind = find(I==1);
[row,col,zz] = ind2sub(size(I),ind);
xmin = min(row); xmax = max(row);
ymin = min(col); ymax = max(col);
zmin = min(zz);  zmax = max(zz);
tol = 5; 
I = I(xmin-tol:xmax+tol,ymin-tol:ymax+tol,zmin-tol:zmax+tol);
x = (1:size(I,2)).*dy;
y = (1:size(I,1)).*dx;
z = (1:size(I,3)).*dz;
xq = linspace(1*dy,size(I,2)*dy,round(length(x)*(dy/res)));
yq = linspace(1*dx,size(I,1)*dx,round(length(y)*(dx/res)));
zq = linspace(1*dz,size(I,3)*dz,round(length(z)*(dz/res)));
I = interp3(x,y,z,I,xq,yq',zq);
figure('pos',[10 10 1000 1000])
imagesc(I(:,:,round(size(I,3)/2))); hold on
axis equal; colormap gray; caxis([0 1])
title('Rotate about Z axis: Click at base FIRST, THEN at apex','FontSize',30)
[yp,zp] = ginput(2);
info.th_rot_z = atan2(abs(diff(yp)),abs(diff(zp)));
th_rot_z = info.th_rot_z;
t_z = [cos(th_rot_z) -sin(th_rot_z) 0 0; sin(th_rot_z) cos(th_rot_z) 0 0; 0 0 1 0; 0 0 0 1];
tform_z = affine3d(t_z);
I_rot_z = imwarp(I,tform_z);
%
%%
figure('pos',[10 10 1000 1000])
imagesc(squeeze(I_rot_z(:,round(size(I_rot_z,2)/2),:)));
axis equal; colormap gray; caxis([0 1])
title('Rotate about X axis: Click at base FIRST, THEN at apex','FontSize',30)
[yp,zp] = ginput(2);
th_rot_x = -atan2(abs(diff(yp)),abs(diff(zp)));
save(['/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/angle_info/',p_class,'_',p_id,'_angle','.mat'],'th_rot_z','th_rot_x')