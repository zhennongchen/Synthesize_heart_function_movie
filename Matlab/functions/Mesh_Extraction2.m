function [fv,fig] = Mesh_Extraction(I,info,print)

if info.downsampling
    %Stepping interval for downsampling
    pixel = info.iso_res.*ones(1,3);
    stp = round(info.res./pixel);

    %Averaging filter
    ff = ones(stp+1);
    ff = ff/sum(ff(:));
    tmp = imfilter(I,ff,'symmetric');

    imsub = tmp(1:stp(1):end,1:stp(2):end,1:stp(3):end);
    im = imsub>info.mesh_thresh;

    % make sure images are binary
    imbw = double(im > max(im(:))/2+min(im(:))/2);

    % Identify connected components
    CC = bwconncomp(imbw);
    numPixels = cellfun(@numel,CC.PixelIdxList);

    % Identify largest component
    [~,idx]= max(numPixels);

    % Make image of only the largest component
    imbw = zeros(size(imbw));
    imbw(CC.PixelIdxList{idx})=1;

    % create the 3D mesh
    fv = isosurface(imbw,0);
else
    fv = isosurface(I,0);
end    

if print
    vertex(:,1) = fv.vertices(:,1);
    vertex(:,2) = fv.vertices(:,3);
    vertex(:,3) = fv.vertices(:,2);
    
    fig = figure('pos',[10 10 1200 1200]);
    patch('Faces',fv.faces,'Vertices',vertex,'FaceColor','red');%,'EdgeColor','none');
    ax = gca; ax.FontSize = 20; ax.FontWeight = 'bold';
    daspect([1,1,1]); view(90,0); camlight; lighting gouraud;
    title('Template Mesh','FontSize',35); ylim([0 info.y_lim]); xlim([0 info.x_lim]); zlim([0 info.z_lim]);
    xlabel('x')
    ylabel('y')
    zlabel('z')
end