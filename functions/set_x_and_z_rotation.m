%%
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

tol = 5; %user input for cropping tolerance  change if min-tol < 0
I = I(xmin-tol:xmax+tol,ymin-tol:ymax+tol,zmin-tol:zmax+tol);

%Interpolating to make it isotropic resolution
x = (1:size(I,2)).*dy;
y = (1:size(I,1)).*dx;
z = (1:size(I,3)).*dz;

xq = linspace(1*dy,size(I,2)*dy,round(length(x)*(dy/res)));
yq = linspace(1*dx,size(I,1)*dx,round(length(y)*(dx/res)));
zq = linspace(1*dz,size(I,3)*dz,round(length(z)*(dz/res)));

I = interp3(x,y,z,I,xq,yq',zq);
%%
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
%%
figure('pos',[10 10 1000 1000])

imagesc(squeeze(I_rot_z(:,round(size(I_rot_z,2)/2),:)));

axis equal; colormap gray; caxis([0 1])

title('Rotate about X axis: Click at base FIRST, THEN at apex','FontSize',30)

[yp,zp] = ginput(2);

info.th_rot_x = -atan2(abs(diff(yp)),abs(diff(zp)));

th_rot_x = info.th_rot_x;
t_x = [1 0 0 0; 0 cos(th_rot_x) -sin(th_rot_x) 0; 0 sin(th_rot_x) cos(th_rot_x) 0; 0 0 0 1];
tform_x = affine3d(t_x);

I_rot = imwarp(I_rot_z,tform_x);
%%
ind = find(I_rot==1);
[row,col,zz] = ind2sub(size(I_rot),ind);

xmin = min(row); xmax = max(row);
ymin = min(col); ymax = max(col);
zmin = min(zz);  zmax = max(zz);