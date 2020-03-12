function [vertices, base_lim, nosmooth_verts] = Strain_Model_InfarctNew(fv,info,E,infarct,smooth,i)

% -------------------------- General functions ----------------------------
% Sorting infarct vertices based on radius from infarct center
[~,radius_ind] = sort(infarct.radius,'ascend');
infarct.Locb = infarct.Locb(radius_ind); % sorting the index locations of infarct vertices in parent mesh in ascending order of radius


% ----------------------- Defining taper functions ------------------------
if strcmp(infarct.taper,'Gaussian')
    
    %Parameters
    temp_x = 0:100; % Random length scale for gaussian function
    a = 1-infarct.center_scaling; %gaussian height
    b = 0; % mean
%     c = 0.035; %standard deviation --> smaller the value, wider the distribution
    c = 0.035;
    
    %Function
    g = a.*exp(-((temp_x-b).^2)./2*c^2);
    infarct_scaling = interp1(1:length(g),g,linspace(1,length(g),length(infarct.radius)))'; %Interpolating to number of vertices in infarct
    
    if infarct.plot_taper == 1 && i == info.tf
        figure('pos',[10 10 1000 1000]);
        plot(1:length(infarct.radius),1-infarct_scaling,'LineWidth',3)
        ax = gca; ax.FontSize = 18; ax.FontWeight = 'bold';
        ylabel('Scaling Value','FontSize',20)
        xlabel('Infarct Center \rightarrow Infarct End','FontSize',20)
        ylim([0 1])
        xlim([1 length(infarct.radius)])
    end
    
    infarct_scaling = infarct_scaling; % Ordering the scaling based on the vertex radius from infarct center
    infarct_scaling = 1 - infarct_scaling;
    
elseif strcmp(infarct.taper,'Linear')
    
    infarct_scaling = linspace(infarct.center_scaling,1,length(infarct.radius))';
    
    if infarct.plot_taper == 1 && i == info.tf
        figure('pos',[10 10 1000 1000]);
        plot(1:length(infarct.radius),infarct_scaling,'LineWidth',3)
        ax = gca; ax.FontSize = 18; ax.FontWeight = 'bold';
        ylabel('Scaling Value','FontSize',20)
        xlabel('Infarct Center \rightarrow Infarct End','FontSize',20)
        ylim([0 1])
        xlim([1 length(infarct.radius)])
    end
    
    infarct_scaling(radius_ind) = infarct_scaling;

elseif strcmp(infarct.taper,'Table-top')
    
    temp_x = -6.9:0.1:5;
    g = (1-infarct.center_scaling)./(1 + exp(-temp_x));
    g = flip(g);
    g = 1 - g;
    
    core = nnz(infarct.radius < (infarct.size - infarct.PIZ));
    piz = nnz(infarct.radius >= (infarct.size - infarct.PIZ));
    
    g = interp1(1:length(g),g,linspace(1,length(g),piz));
    
    infarct_scaling = [infarct.center_scaling.*ones(1,core), g];
    
    if infarct.plot_taper == 1 && i == info.tf
        figure('pos',[10 10 1000 1000]);
        plot(1:length(infarct.radius),infarct_scaling,'LineWidth',3)
        ax = gca; ax.FontSize = 18; ax.FontWeight = 'bold';
        ylabel('Scaling Value','FontSize',20)
        xlabel('Infarct Center \rightarrow Infarct End','FontSize',20)
        ylim([0 1])
        xlim([1 length(infarct.radius)])
    end    
    
elseif strcmp(infarct.taper,'2D Sigmoid')
    
    temp_x = -3:0.1:4; temp_y = -3:0.1:4;
    [X,Y] = meshgrid(temp_x,temp_y);

    g = (sqrt(1-infarct.center_scaling)./(1 + exp(-1.25*X))).*(sqrt(1-infarct.center_scaling)./(1 + exp(-1.25*Y)));
    g = [g; flip(g)];
    g = [g, flip(g,2)];

    infarct_scaling = interp1((1:size(g,1)).*info.res,g,linspace(1*info.res,size(g,1)*info.res,min(size(infarct.projection))));
    infarct_scaling = interp1((1:size(g,1)).*info.res,infarct_scaling',linspace(1*info.res,size(g,1)*info.res,min(size(infarct.projection)))); infarct_scaling = 1 - infarct_scaling';
    
    [~,dim] = max(size(infarct.projection));
    new_row = max(size(infarct.projection)) - min(size(infarct.projection));
    
    if mod(new_row,2) == 0
        nr = 0;
    else 
        nr = 1;
    end
    
    if dim == 1
        infarct_scaling = padarray(infarct_scaling,[nr 0],'replicate','pre');
        infarct_scaling = padarray(infarct_scaling,[((new_row-nr)/2) 0],'replicate');
    else
        infarct_scaling = padarray(infarct_scaling,[0 nr],'replicate','pre');
        infarct_scaling = padarray(infarct_scaling,[0 ((new_row-nr)/2)],'replicate');
    end    
    
    infarct.Locb = infarct.projection(~isnan(infarct.projection));
    infarct_scaling = infarct_scaling(~isnan(infarct.projection));

end    


% -------------------------- General functions ----------------------------
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
    slice_index_sorted{j} = slice_index{j}(ind); %Sorting the indices from low to high theta
    
    R{j} = sqrt((temp(:,1) - ctrd(1)).^2 + (temp(:,3) - ctrd(2)).^2); % Calculating radius of all points in slice
    
    clear temp
end    


% ------------------------- Longitudinal Strain ---------------------------
count = 1;
new_slice{1} = z_uni(1)*ones(size(t{1},1),1); % Apex slice does not move
for j = 2:length(z_uni) % slice loop
    for k = 1:size(t{j},1) % points within slice loop
        
        [~,min_ind] = min(abs(t{j-1}-t{j}(k))); %Finding point in the previous slice with closest theta --> "to detect point directly below"
        
        if ismember(slice_index_sorted{j}(k),infarct.Locb)
            [~,loc] = ismember(slice_index_sorted{j}(k),infarct.Locb);
            new_slice{j}(k) = new_slice{j-1}(min_ind) + (1 + infarct_scaling(loc)*E.ll(i))*(z_int(j-1));
        else
            new_slice{j}(k) = new_slice{j-1}(min_ind) + (1 + E.ll(i))*(z_int(j-1)); %Strain function [z'(z) = z'(z-1) + strain*[z(z) - z(z-1)]
            if j == length(z_uni) && count == 1
                base_lim = new_slice{j}(k);
                count = 2;
            end    
        end    
        
    end
end

y_disp = new_slice{1}(rev{1});
for  j = 2:length(z_uni)
    y_disp = [y_disp;[new_slice{j}(rev{j})]'];
end


% ------------------------ Circumferential Strain -------------------------

for j = 1:length(z_uni)
    for k = 1:size(t{j},1) % points within slice loop
        
        if ismember(slice_index{j}(k),infarct.Locb)
            [~,loc] = ismember(slice_index{j}(k),infarct.Locb);
            r{j}(k) = R{j}(k)*(1 + infarct_scaling(loc)*E.cc(i,j));
        else
            r{j}(k) = R{j}(k)*(1 + E.cc(i,j));
        end    
        
    end
    r{j} = r{j}';
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
    p = patch('Faces',fv.faces,'Vertices',vertices,'FaceColor','red');
    ax = gca; ax.FontSize = 20; ax.FontWeight = 'bold';
    daspect([1,1,1]); view(90,0); camlight; lighting gouraud;
    title(['Target Mesh ',num2str(i)],'FontSize',35); ylim([0 info.y_lim]); xlim([0 info.x_lim]); zlim([0 info.z_lim]);
end