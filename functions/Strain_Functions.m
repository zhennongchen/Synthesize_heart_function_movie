function E = Strain_Functions(fv,info)

%Defining normalized distance from base to apex [0 @base and 1 @apex]
z_uni = unique(fv.vertices(:,2)); % Determining the unique 'z' values --> each value represents a slice


z_star = linspace(1,0,length(z_uni)); %Normalized z* from apex to base cause strain model works from apex to base

%LONGITUDINAL STRAIN vs TIME
%Strain function
E.ll = -0.21*info.EF; %J. Shi (2016) for GLS of endo, cam change this

%Interpolating for the values for time frames
E.ll = linspace(0,E.ll,info.tf);

%CIRCUMFERENTIAL STRAIN vs TIME
%Strain function
E.cc = (-0.1.*z_star - 0.34)*info.EF; %J. Shi (2016) for CS of endo (table 3), can change this

%Interpolating for the values for time frames
E.cc = [E.cc; zeros(1, length(E.cc))];
E.cc = interp1(1:2,E.cc,linspace(1,2,info.tf));
E.cc = flip(E.cc);

%AZIMUTHAL DISPLACEMENT vs TIME
%Displacement function
E.theta = ((-19.9.*z_star + 6.9).*pi/180)*info.EF; %Kocabay (2014) & linear fit by CC Moore (2000), can change this

%Interpolating for the values for time frames
E.theta = [E.theta; zeros(1, length(E.theta))];
E.theta = interp1(1:2,E.theta,linspace(1,2,info.tf));
E.theta = flip(E.theta);