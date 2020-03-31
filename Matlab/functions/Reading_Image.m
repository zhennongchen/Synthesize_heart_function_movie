function [I,final_limit] = Reading_Image(image_name,info,print,tol)

data = load_nii(image_name);
dx = data.hdr.dime.pixdim(2);
dy = data.hdr.dime.pixdim(3);
dz = data.hdr.dime.pixdim(4);

res = info.iso_res;

%Extracting only the LV whose tag is 1
I = zeros(size(data.img));
I(data.img==1) = 1;

%Direction matrix Transformation from .nii to .mat
I = permute(I,[2 1 3]);
I = flip(I,1);
I = flip(I,2);
I = flip(I,3);

%Cropping data set for data saving
ind = find(I==1);
[row,col,zz] = ind2sub(size(I),ind);

xmin = min(row); xmax = max(row);
ymin = min(col); ymax = max(col);
zmin = min(zz);  zmax = max(zz);

tol = tol; %user input for cropping tolerance
I = I(xmin-tol:xmax+tol,ymin-tol:ymax+tol,zmin-tol:zmax+tol);

%Interpolating to make it isotropic resolution
x = (1:size(I,2)).*dy;
y = (1:size(I,1)).*dx;
z = (1:size(I,3)).*dz;

xq = linspace(1*dy,size(I,2)*dy,round(length(x)*(dy/res)));
yq = linspace(1*dx,size(I,1)*dx,round(length(y)*(dx/res)));
zq = linspace(1*dz,size(I,3)*dz,round(length(z)*(dz/res)));

I = interp3(x,y,z,I,xq,yq',zq);

%z rotation
disp('Rotating about the z axis...')
th_rot_z = info.th_rot_z;
t_z = [cos(th_rot_z) -sin(th_rot_z) 0 0; sin(th_rot_z) cos(th_rot_z) 0 0; 0 0 1 0; 0 0 0 1];
tform_z = affine3d(t_z);

I = imwarp(I,tform_z);

% x rotation
disp('Rotating about the x axis...')
th_rot_x = info.th_rot_x;
t_x = [1 0 0 0; 0 cos(th_rot_x) -sin(th_rot_x) 0; 0 sin(th_rot_x) cos(th_rot_x) 0; 0 0 0 1];
tform_x = affine3d(t_x);

I = imwarp(I,tform_x);

disp('Done rotating')

% Final Crop
ind = find(I==1);
[row,col,zz] = ind2sub(size(I),ind);

xmin = min(row); xmax = max(row);
ymin = min(col); ymax = max(col);
zmin = min(zz);  zmax = max(zz);

I = I(xmin-tol:xmax+tol,ymin-tol:ymax+tol,zmin-tol:zmax+tol);

final_limit = [xmax,xmin,ymax,ymin,zmax,zmin];
%Removing the weird voxel values as a result of the rotation
A = zeros(size(I));
A(I>0.1) = 1;

%Keeping only the single largest connected region (May get disconnected due to the kicking out of some voxels
CC = bwconncomp(A,6);
numPixels = cellfun(@numel,CC.PixelIdxList);
[~,idx] = max(numPixels);

mask_biggest = zeros(size(A));
mask_biggest(CC.PixelIdxList{idx}) = 1;

I = mask_biggest;
ind = find(I==1);
[row,col,zz] = ind2sub(size(I),ind);
xmin = min(row); xmax = max(row);
ymin = min(col); ymax = max(col);
zmin = min(zz);  zmax = max(zz);
final_limit = []; final_limit = [xmax,xmin,ymax,ymin,zmax,zmin];
if print == 1
    figure; imagesc(I(:,:,round(size(I,3)/2))); axis equal; colormap gray;
end    