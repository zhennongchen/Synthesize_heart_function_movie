function infarct = Infarct_Model_no_manual_input(fv,infarct,info)

%Infarct Location: Mid_Anterior
%Infarct Plane:    x-y; y is the Long Axis of the ventricle

%Detect points within infarct radius
r = sqrt((fv.vertices(:,1) - infarct.center(1)).^2 + (fv.vertices(:,2) - infarct.center(2)).^2 + (fv.vertices(:,3) - infarct.center(3)).^2);
ind = r <= infarct.size;

%Detect faces belonging to these infarct vertices
dummy = sum([ind(fv.faces(:,1)) ind(fv.faces(:,2)) ind(fv.faces(:,3))],2) == 3;
faces = [fv.faces(dummy,1) fv.faces(dummy,2) fv.faces(dummy,3)];

%Isolate disconnected meshes
facecell = finddisconnsurf(faces);

if numel(facecell)>7
    disp('Something wrong')
    return;
end    

%Choose mesh object you want to keep
col = {'red','blue','green','black','cyan','yellow','magenta'};
figure('pos',[10 10 1200 1200]);

vertex(:,1) = fv.vertices(:,1);
vertex(:,2) = fv.vertices(:,3);
vertex(:,3) = fv.vertices(:,2);

%Displaying the multiple mesh objects
for i = 1:numel(facecell)
    patch('Faces',facecell{i},'Vertices',vertex,'FaceColor',col{i}); hold on;    
end
ax = gca; ax.FontSize = 20; ax.FontWeight = 'bold';
daspect([1,1,1]); view(55,-4); camlight; lighting gouraud;
xlabel('x');
ylabel('y');
zlabel('z');
title('Choose desired mesh object...','FontSize',35); ylim([0 info.y_lim]); xlim([0 info.x_lim]); zlim([0 info.z_lim]);

% %Specifying colors for user selected choice
% for j = 1:numel(facecell)
%     fprintf([num2str(j),'. ',col{j},'\n'])
% end
% choice = str2double(input('Choose mesh Object: ','s'));

%Choosing only the faces wanted by the user
choice = 1;
infarct.Faces = facecell{choice};

%Extracting the vertices corresponding to those faces
temp = infarct.Faces(:);
temp = unique(temp);

infarct.Vertices = fv.vertices(temp,:);

%Obtaining the index locations of the vertices of the infarct mesh in the Parent vertices array
[~, infarct.Locb] = ismember(infarct.Vertices,fv.vertices,'rows');

%Calculating radius of infarct vertices
infarct.radius = sqrt((infarct.Vertices(:,1) - infarct.center(1)).^2 + (infarct.Vertices(:,2) - infarct.center(2)).^2 + (infarct.Vertices(:,3) - infarct.center(3)).^2);