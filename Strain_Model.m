function [vertices, base_lim, nosmooth_verts] = Strain_Model(fv,info,E,smooth,i)

% ------------------------- General functions ---------------------------
ctrd = [mean(fv.vertices(:,1)) mean(fv.vertices(:,3))];

z_uni = unique(fv.vertices(:,2)); % Determining the unique 'z' values --> each value represents a slice
z_int = diff(z_uni); % Determining subsequent intervals in 'z' between slices

% Extracting slices and sorting points in slices from low to high theta
for j = 1:length(z_uni)
    slice_index{j} = find(fv.vertices(:,2) == z_uni(j));
    
    temp = fv.vertices(slice_index{j},:); %Extracting all ventricle points belonging to the particular slice
    
    % Calculating thetas of all points in the slice and sorting from low to high theta
    thetas = atan2(temp(:,3) - ctrd(2),temp(:,1) - ctrd(1));
    thetas(thetas<0) = 2*pi + thetas(thetas<0);
    [thetas, ind] = sort(thetas,'ascend');
    [~,rev{j}] = sort(ind);
    t{j} = thetas;
    
    R{j} = sqrt((temp(:,1) - ctrd(1)).^2 + (temp(:,3) - ctrd(2)).^2); % Calculating radius of all points in slice
    
    clear temp
end    


% ------------------------- Longitudinal Strain ---------------------------
count = 1;
new_slice{1} = z_uni(1)*ones(size(t{1},1),1); % Apex slice does not move
for j = 2:length(z_uni) % slice loop
    for k = 1:size(t{j},1) % points within slice loop
        
        [~,min_ind] = min(t{j-1}-t{j}(k)); %Finding point in the previous slice with closest theta --> "to detect point directly below"
        new_slice{j}(k) = new_slice{j-1}(min_ind) + (1 + E.ll(i))*(z_int(j-1)); %Strain function [z'(z) = z'(z-1) + strain*[z(z) - z(z-1)]
        if j == length(z_uni) && count == 1
            base_lim = new_slice{j}(k);
            count = 2;
        end 
        
    end
end

y_disp = new_slice{1}(rev{1});
for  j = 2:length(z_uni)
    y_disp = [y_disp;[new_slice{j}(rev{j})]'];
end


% ------------------------ Circumferential Strain -------------------------

for j = 1:length(z_uni)
    r{j} = R{j}.*(1 + E.cc(i,j));
end    


% ------------------------ Azimuthal Displacement -------------------------
for j = 1:length(z_uni)
    t_new{j} = t{j}(rev{j}) + E.theta(i,j);
end


% ------------ Converting back to Cartesian Coordinate System -------------
for j = 1:length(z_uni)
    x_s{j} = ctrd(1) + r{j}.*cos(t_new{j});
    z_s{j} = ctrd(2) + r{j}.*sin(t_new{j});
end

x_v = x_s{1};
z_v = z_s{1};
for j = 2:length(z_uni)
    x_v = [x_v; x_s{j}];
    z_v = [z_v; z_s{j}];
end


% ------------ Re-sorting the coordinates to original index locations -------------

temp = zeros(size(fv.vertices,1),3);

indexes = slice_index{1};
for j = 2:length(z_uni)
    indexes = [indexes; slice_index{j}];
end

temp(indexes,1) = x_v;
temp(indexes,2) = y_disp;
temp(indexes,3) = z_v;

%Returning the non-smoothed vertices
nosmooth_verts(:,1) = temp(:,1); nosmooth_verts(:,2) = temp(:,3); nosmooth_verts(:,3) = temp(:,2);

%Smoothing process
if smooth.switch
    
    [conn,~,~] = meshconn(fv.faces,length(temp));
    %Running the smoothing function choosing the 'laplacian' filter option
    verts = smoothsurf(temp,[],conn,smooth.iter(i),smooth.alpha(i),smooth.method);
else
    verts = temp;
end

%Returning the smooth vertices
vertices(:,1) = verts(:,1);
vertices(:,2) = verts(:,3); 
vertices(:,3) = verts(:,2); 

clear verts

if info.print == 1 && i == info.tf
    figure('pos',[10 10 1200 1200]);
    p = patch('Faces',fv.faces,'Vertices',vertices,'FaceColor','red');%,'EdgeColor','none');
    ax = gca; ax.FontSize = 20; ax.FontWeight = 'bold';
    daspect([1,1,1]); view(55,-4); camlight; lighting gouraud;
    title(['Target Mesh ',num2str(i)],'FontSize',35); ylim([0 info.y_lim]); xlim([0 info.x_lim]); zlim([0 info.z_lim]);
end