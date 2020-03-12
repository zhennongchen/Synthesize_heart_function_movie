function I = Convex_hull_PapFilling(I,tol)

temp = I;
        
% Cropping data set for data saving
ind = find(temp==1);
[row,col,zz] = ind2sub(size(temp),ind);

temp = temp(min(row)-tol:max(row)+tol,min(col)-tol:max(col)+tol,min(zz)-tol:max(zz)+tol);

%Obtaining convex hull of LV
s = regionprops3(temp,'BoundingBox','ConvexImage');

%Resizing the bounding box
convexhull = zeros(size(temp));
convexhull(ceil(s.BoundingBox(2)):ceil(s.BoundingBox(2)) + s.BoundingBox(5)-1,...
    ceil(s.BoundingBox(1)):ceil(s.BoundingBox(1)) + s.BoundingBox(4)-1,...
    ceil(s.BoundingBox(3)):ceil(s.BoundingBox(3)) + s.BoundingBox(6)-1) = double(s.ConvexImage{1});

%Eroding the hull to identify paps
convexhull = imerode(convexhull,strel('sphere',8));

img_subtract = convexhull - temp;
img_subtract(img_subtract==-1) = 0;

CC = bwconncomp(img_subtract,18);
numPixels = cellfun(@numel,CC.PixelIdxList);

% Identify largest component
[~,idx]= maxk(numPixels,5);

% Dilating paps to circumvent convex hull erosion
temp2 = zeros(size(temp));
temp2(CC.PixelIdxList{idx(1)})=1;
temp2(CC.PixelIdxList{idx(2)})=1;
temp2 = imdilate(temp2,strel('sphere',6));

temp(temp2==1) = 1;

dummy = zeros(size(I));
dummy(min(row)-tol:max(row)+tol,min(col)-tol:max(col)+tol,min(zz)-tol:max(zz)+tol) = temp;

I(dummy == 1) = 1;

clear CC numPixels idx
CC = bwconncomp(I,6);
numPixels = cellfun(@numel,CC.PixelIdxList);
[~,idx]= max(numPixels);

I = zeros(size(I)); I(CC.PixelIdxList{idx}) = 1;