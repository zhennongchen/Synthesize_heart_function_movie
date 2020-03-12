%% 

addpath('/Users/ashish/Google_Drive/PhD/nii_reading')
addpath('/Users/ashish/Google_Drive/PhD/Mesh_Fun/Heart_Model/Biological/Function_Scripts/')
addpath(genpath('/Users/ashish/Google_Drive/PhD/Mesh_Fun/iso2mesh_mac'))

fr = 0;
image_name = ['/Users/ashish/Documents/PhD/Mesh_Fun/Heart_Model/P_000/P000_',num2str(fr),'.nii.gz'];

info.tf = 20; %number of time frames to systole
info.iso_res = 0.5; %Isotropic resolution for rotation (prior to rotation)

info.th_rot_z = 40*pi/180;
info.th_rot_x = -19*pi/180;

info.downsampling = 1; %flag for downsampling

if info.downsampling
    info.res = 2; %Desired resolution for meshes
    info.x_lim = 35*(2/info.res); info.y_lim = 35*(2/info.res); info.z_lim = 50*(2/info.res);
else
    info.res = info.iso_res;
    info.x_lim = 120; info.y_lim = 140; info.z_lim = 220;
end

% Smoothing parameters
smoothing.switch = 1;
smoothing.iter = linspace(0,4,info.tf);
smoothing.alpha = linspace(0,0.4,info.tf);
smoothing.method = 'lowpass';


%% Reading Image

print = 0; %flag for generating a slice of the image

I = Reading_Image(image_name,info,print);

disp('Done Prepping Image');

clear p0 print fr image_name


%% Removing Paps from Template Image

tol = 5;
I = Convex_hull_PapFilling(I,tol);

clear tol

disp('Paps removed from template')


%% Extracting mesh

print = 1;
info.mesh_thresh = 0.5; %Threshold for cleaning up post runnning the averaging filter

fv = Mesh_Extraction(I,info,print);

disp('Done Extracting the mesh');

clear print

%% Infarct Model

clear infarct
info.infarct = 1; %flag for strain model for infarction

if info.infarct
    
    if info.downsampling
        infarct.center = [14, 24, 5];  %values from matlab patch are to be input in [x,z,y];
%         infarct.center = [15, 27, 5];  %old value
%         infarct.center = [3 26 17]; %for 1mm resolution
    else
        infarct.center  = [65, 120, 16.5]; %anterior: ; :septum: [24.5 118 75];
    end    

    infarct.center_scaling = 1 - 0.65; %Enter (1 - %infarct) %Hypo = 0.7; xxxx(NOT USED )subtle hypo = 0.45xxxxxx; subtle hypo = 0.40
    infarct.taper = '2D Sigmoid'; % 1) 'Gaussian' for smooth taper off; 2) 'Table-top', 3) 'Linear' and 4) '2D Sigmoid'
    infarct.plot_taper = 0; %flag for plotting taper function
    
    infarct.core = 0/info.res; %enter radius of infarct core in mm
    infarct.PIZ = 25/info.res; %enter Peri-infarct zone radius in mm
    infarct.size = infarct.PIZ + infarct.core;
    %enter radius in mm eg:'10' %40(aha1),27(aha2),20(aha3),13.5(aha4); -size severity sigmoid
    
    infarct = Infarct_Model(fv,infarct,info);
    
    if strcmp(infarct.taper,'2D Sigmoid')
        infarct = Surface_Flattening(fv,infarct);
    end    
        
    disp('Done Extracting the infarct faces & vertices');
else
    disp('No infarct');
end

%% Infarct Strain model

% EF
info.ef_normal = 70; % Computed from Blender
info.ef_desired = 70;

info.EF = info.ef_desired/info.ef_normal; % 1 - Normal EF; 0 - No EF

%Computing the strain functions
E = Strain_Functions(fv,info);

%Flag for printing meshes
info.print = 1;

if info.infarct == 1
    for i = 1:info.tf
        [Mesh.Vertices(:,:,i), base_lim(i), Mesh.NoSmooth_Verts(:,:,i)] = Strain_Model_InfarctNew(fv,info,E,infarct,smoothing,i);
    end
else
    for i = 1:info.tf
        [Mesh.Vertices(:,:,i), base_lim(i), Mesh.NoSmooth_Verts(:,:,i)] = Strain_Model(fv,info,E,smoothing,i);
    end
end    

Mesh.Vertices(:,:,1) = round(Mesh.Vertices(:,:,1)); %Very small discrepancy between the vertices saved from pap muscle deletion and raw vertex coordinates from isosurface
Mesh.NoSmooth_Verts(:,:,1) = Mesh.Vertices(:,:,1);
Mesh.Faces = fv.faces;
disp('Strain model finished');


%% Making Systolic contraction movie of endocardium

makemovie = 1;

if makemovie == 1
    writerObj = VideoWriter('/Users/ashish/Desktop/Infarct_Test','MPEG-4');
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
        title(['Time: ',num2str(i),'ms'],'FontSize',25)
        
        frame = getframe(f1);
        writeVideo(writerObj, getframe(gcf));
    end
    close(writerObj);
    
    disp('Done making movie')
end