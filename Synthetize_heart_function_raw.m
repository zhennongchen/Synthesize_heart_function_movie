%% 
clear all
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/Matlab/NIfTI image processing/');
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/Matlab/iso2mesh');
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/Matlab/functions');
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/angle_info');

load('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/Matlab/patient_list.mat')
%%
clear point_list
patient_num = 1;
patient_class = "ucsd_toshiba";
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
%% Reading Image
clear I
print = 1; %flag for generating a slice of the image

read_size = ['/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/reading_image_info/',p_class,'_',p_id,'_read.mat'];
load(read_size)

[I,final_limit] = Reading_Image(image_name,info,print,Reading_image_size);

disp('Done Prepping Image');
close all

%%
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
%% Extracting mesh

print = 1;
info.mesh_thresh = 0.5; %Threshold for cleaning up post runnning the averaging filter

fv = Mesh_Extraction(I,info,print);

disp('Done Extracting the mesh');
%close all
clear print
%% Infarct Model
clear infarct
infarct_location = ['/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/infarct_location_info/',p_class,'_',p_id,'_infarct_location.mat'];
load(infarct_location)
idx = randperm(8);
disp(idx(1));
center_raw = point_list(idx(1),:);
%
info.infarct = 1; %flag for strain model for infarction

if info.infarct
    
    if info.downsampling
        infarct.center = [14, 24, 5];  %values from matlab patch are to be input in [x,z,y];
%         infarct.center = [15, 27, 5];  %old value
%         infarct.center = [3 26 17]; %for 1mm resolution
    else
        infarct.center  = [center_raw(1) center_raw(3) center_raw(2)]; %anterior: ; :septum: [24.5 118 75];
        % click to get [x,y,z], center = [x,z,y]
    end    
    
    infarct.center_scaling = 1 - 0.9; %Enter (1 - %infarct) % hypokinesia = 80% reduction in strain and subtle hypokinesia = 40% reduction in strain
    infarct.taper = '2D Sigmoid'; % 1) 'Gaussian' for smooth taper off; 2) 'Table-top', 3) 'Linear' and 4) '2D Sigmoid'
    infarct.plot_taper = 0; %flag for plotting taper function
    
    infarct.core = 0/info.res; %enter radius of infarct core in mm
    infarct.PIZ = 25/info.res; %enter Peri-infarct zone radius in mm
    infarct.size = infarct.PIZ + infarct.core;
    %enter radius in mm eg:'10' %40(aha1),27(aha2),20(aha3),13.5(aha4); -size severity sigmoid
    
    infarct = Infarct_Model_no_manul_input(fv,infarct,info);
    
    if strcmp(infarct.taper,'2D Sigmoid')
        infarct = Surface_Flattening(fv,infarct);
    end    
        
    disp('Done Extracting the infarct faces & vertices');
else
    disp('No infarct');
end
close all
%% Infarct Strain model
% set EF
% normal LV has EF from 70 to 90
% abnormal LV has EF from 10 to 30

info.ef_normal = 70; % Computed from Blender
info.ef_desired = 75;
    
info.EF = info.ef_desired/info.ef_normal; % 1 - Normal EF; 0 - No EF
disp(info.ef_desired)
disp(info.EF)
%Computing the strain functions
E = Strain_Functions(fv,info); % can change strain values in this strain_functions.m 

%Flag for printing meshes
info.print = 0;

    if info.infarct == 1
     for i = 1:info.tf
            [Mesh.Vertices(:,:,i), base_lim(i), Mesh.NoSmooth_Verts(:,:,i)] = Strain_Model_InfarctNew(fv,info,E,infarct,smoothing,i);
     end
    else
        for iii = 1:info.tf
        [Mesh.Vertices(:,:,iii), base_lim(iii), Mesh.NoSmooth_Verts(:,:,iii)] = Strain_Model(fv,info,E,smoothing,iii);
        end
    end    

    Mesh.Vertices(:,:,1) = round(Mesh.Vertices(:,:,1)); %Very small discrepancy between the vertices saved from pap muscle deletion and raw vertex coordinates from isosurface
    Mesh.NoSmooth_Verts(:,:,1) = Mesh.Vertices(:,:,1);
    Mesh.Faces = fv.faces;
    disp('Strain model finished');
%% Making Systolic contraction movie of endocardium

makemovie = 1;

if makemovie == 1
    save_path = ['/Volumes/McVeighLab/projects/Zhennong/Video_Prediction/Synthesized_Infarction_movie/',p_class,'_',p_id,'_',num2str(round(1-infarct.center_scaling,2)),'_',num2str(round(info.ef_desired,2)),'%'];
    writerObj = VideoWriter(save_path,'Motion JPEG AVI');
    writerObj.FrameRate = 20;
    
    % open the video writer
    open(writerObj);

    % write the frames to the video
    f1 = figure('pos',[10 10 2200 2000]);
    
    for i = [1:2:info.tf info.tf:-2:1]
        clf;
        
        patch('Faces',Mesh.Faces,'Vertices',Mesh.Vertices(:,:,i),'FaceColor','r','EdgeColor','none');
        ax = gca; ax.FontSize = 20; ax.FontWeight = 'bold'; axis off
        daspect([1,1,1]); view(90,0); camlight; lighting gouraud; 
        ylim([0 info.y_lim]); xlim([0 info.x_lim]); zlim([0 info.z_lim]);
        %title(['Time: ',num2str(i),'ms'],'FontSize',25)
        
        frame = getframe(f1);
        writeVideo(writerObj, getframe(gcf));
    end
   
    close(writerObj);
    close all
    
end 

