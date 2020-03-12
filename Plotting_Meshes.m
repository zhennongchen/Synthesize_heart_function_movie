%%
i = 1;
figure('pos',[10 10 2000 1000])
subplot(1,2,1)
patch('Faces',faces,'Vertices',aha5.mesh(:,:,i),'FaceVertexCData',aha5.Th_SQ(:,i),'FaceColor','flat','EdgeColor','none');
co = colorbar; co.FontSize = 20; co.FontWeight = 'bold'; set(get(co,'Title'),'string','SQUEEZ');
caxis([0.75 0.85]); colormap(cmap); 
daspect([1 1 1]); view(-20,0); camlight; lighting gouraud; view(0,0)
title([{'Theoretical SQUEEZ'}],'FontSize',35);
ylim([0 35]); xlim([0 35]); zlim([0 50]);

subplot(1,2,2)
patch('Faces',faces,'Vertices',aha5.CPD(:,:,i),'FaceVertexCData',aha5.CPD_SQ(:,i),'FaceColor','flat','EdgeColor','none');
co = colorbar; co.FontSize = 20; co.FontWeight = 'bold'; set(get(co,'Title'),'string','SQUEEZ');
caxis([0.75 0.85]); colormap(cmap); 
daspect([1 1 1]); view(-20,0); camlight; lighting gouraud; view(0,0)
title([{'CPD SQUEEZ'}],'FontSize',35);
ylim([0 35]); xlim([0 35]); zlim([0 50]);

%%
i = 17;
figure('pos',[10 10 1000 1000])
patch('Faces',Mesh(i).faces,'Vertices',Mesh(i).crop_verts,'FaceColor','r');
daspect([1 1 1]);
xlim([info.xlim]); ylim([info.ylim]); zlim([info.zlim]);%
xlabel('x'); ylabel('y'); zlabel('z')

%%

i = 8;
figure('pos',[10 10 1000 1000])
patch('Faces',Mesh(info.template).faces,'Vertices',Mesh(i).CPD,'FaceColor','r');
daspect([1 1 1]);
xlim([info.xlim]); ylim([info.ylim]); zlim([info.zlim]);%

%%

i = 1;
figure('pos',[10 10 1000 1000])
patch('Faces',Mesh(info.template).faces,'Vertices',Mesh(i).rotated_verts,'FaceColor','r');
daspect([1 1 1]);
xlim([info.rot_xlim]); ylim([info.rot_ylim]); zlim([info.rot_zlim]);%
xlabel('x'); ylabel('y'); zlabel('z')

%%

i = 5;
figure('pos',[10 10 1000 1000])
patch('Faces',Mesh(i).HiResFaces,'Vertices',Mesh(i).HiResCropVerts,'FaceColor','r');
daspect([1 1 1]);
xlim([info.high_xlim]); ylim([info.high_ylim]); zlim([info.high_zlim]);
xlabel('x'); ylabel('y'); zlabel('z')


%%

load('/Users/ashish/Google_Drive/MS_Fractals/CT_segmentation_Ashish/Fractal_Code/cmap_new.mat') % RSct colormap

i = 8;
figure('pos',[10 10 1000 1000])
patch('Faces',faces,'Vertices',CPD_inf(:,:,161),'FaceVertexCData',SQ_inf.CPD(:,161),'FaceColor','flat','EdgeColor','none');
co = colorbar; co.FontSize = 20; co.FontWeight = 'bold'; set(get(co,'Title'),'string','RS_{CT}');
caxis([0.6 1.1]); colormap(cmap); 
daspect([1 1 1]);
title([{'SQUEEZ'}],'FontSize',35);
xlim([0 35]); ylim([0 35]); zlim([0 50]);%
% xlim([info.rot_xlim]); ylim([info.rot_ylim]); zlim([info.rot_zlim]);


%%

figure('pos',[10 10 1000 1000])
patch('Faces',faces,'Vertices',CPD_inf(:,:,161),'FaceColor','r');
daspect([1 1 1]); view(90,0)
xlim([0 35]); ylim([0 35]); zlim([0 50]);%
xlabel('x'); ylabel('y'); zlabel('z')