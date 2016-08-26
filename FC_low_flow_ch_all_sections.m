clear all
close all

% changing channel geometry
% Low Flow channel configuration: French Creek
% 10/22/2015, sjb

% 8/22/2016, Gwyn: Bottom width = 2, changed textscan to dlmread, new jpg and csv outputs
% 8/26/2016, GP: Bottom width = 7, added notch at depth -1ft, new jpg and csv outputs

cd('C:\Users\gwynethp\Documents\My Projects\32430A French Creek\Code\Transect_Element_1')

file_name = 'Transects_existing rev_run_1.txt';
fid = fopen(file_name);
header = fgetl(fid);
tr_name = str2num(header);
tr_num = length(tr_name);
frewind(fid);

fmt = repmat('%f%f',1,tr_num);
%C = textscan(fid,fmt,'delimiter','\t','headerlines',2); not working correctly for me (GP) due to differing column lengths
C = dlmread('Transects_existing rev_run_1.csv',",",2,0);
fclose(fid);

% C includes all transects (34) information with some tailing NaN. We will not use the first 6 transect output - they have separate cross-section requirements.
zB = 4.3;  % zB: elevation of Bench
% bWid = 10; % bottom width
bWid = 7; % bottom width
nWid = 2; % notch width

for i = 1:tr_num 
    
    
    %%
    x = C(:,2*i-1); z = C(:,2*i);
    [zC, Ith] = min(z);  % identify lowest point value and index: z(Ith) = zC
    %xC = x(Ith);         % x at thalweg (xC)
    
    %% Alternatively, find all points below 4.3' and new channel to be center around it.
    
    % 1) identify nearest points at z = 4.3
    % 2) calculate intersection points at z = 4.3 using interp1
    
    zLower = find(z<zB);
    ind_1 = zLower(1); ind_2 = zLower(end);
    
    % these are x coordinates at z = zB (4.3')
    x_L_zB = interp1(z(ind_1-1:ind_1),x(ind_1-1:ind_1),zB);
    x_R_zB = interp1(z(ind_2:ind_2+1),x(ind_2:ind_2+1),zB);
    
    % new xC
    xC = (x_L_zB+x_R_zB)/2;
    
    
    %%
    plot(x,z,'.-')
    % 1) delete z < 4.3' from existing
    % 2) check the existing width at z = 4.3 is greater than proposed width
    %    new width at bench: 4*(4.3-zc) + bWid
    %       bWid = bottom width
    %       zc = thalweg elevation
    
    %% new (narrow) channel geometry: trapezoidal shape
    
    zNew = [zB zC zC zB];
    x1 = xC-(2*(zB-zC)+bWid/2);
    x2 = xC+(2*(zB-zC)+bWid/2);
    xNew = [x1 xC-bWid/2 xC+bWid/2 x2];
    
    %% new "notch" in narrow channel: trapezoidal shape
    zC_notch = zC - 1; %lowest point of notch is 1ft down
    zNew_notch = [zB zC zC zC_notch zC_notch zC zC zB];
    x1_notch = xC-(2*(zC-zC_notch)+nWid/2);
    x2_notch = xC+(2*(zC-zC_notch)+nWid/2);
    xNew_notch = [x1 xC-bWid/2 x1_notch xC-nWid/2 xC+nWid/2 x2_notch xC+bWid/2 x2];
    
    %% remove old section
    %  1) z < zB
    %  2) min(xNew) < x < max(xNew)
    
    
    % LEFT bank
    xL = x(z>4.3 & x< x1);
    zL = z(z>4.3 & x< x1);
    
    % Right bank
    xR = x(z>4.3 & x> x2);
    zR = z(z>4.3 & x> x2);
    
    %% flood plain (flat section at z = 4.3')
    % left bank
    [iL,~]=find(x==xL(end));
    
    
    xsecL = x(iL:iL+1);
    zsecL = z(iL:iL+1);
    v_LBank = interp1(zsecL,xsecL,4.3);
    z_bankL = zB;
    
    if v_LBank > x1 || isnan(v_LBank)
        v_LBank = [];
        z_bankL = [];
    end
    
    % right bank
    [iR,~]=find(x==xR(1));
    
    xsecR = x(iR-1:iR);
    zsecR = z(iR-1:iR);
    
    v_RBank = interp1(zsecR,xsecR,4.3);
    z_bankR = zB;
    
    if v_RBank < x2 || isnan(v_RBank)
        v_RBank = [];
        z_bankR = [];
    end
    
    %% splicing
    xN = [xL; v_LBank; xNew_notch'; v_RBank; xR];
    zN = [zL; z_bankL; zNew_notch'; z_bankR; zR];
    hold on
    plot(xN,zN,'r.-')
    grid
    
    %% plotting
    fig_name = regexprep(num2str(tr_name(i)),'\.','_');
    title(sprintf('transect: %s',num2str(tr_name(i))))
    xlabel('ft')
    ylabel('ft')
    print(1,['jpg\' fig_name],'-djpeg')
    hold off
    close all
    %% writing out new x-z transects
    fidw = fopen(sprintf('csv\\%s.csv',fig_name),'wt');
    fprintf(fidw,'new X, new Z\n');
    fprintf(fidw,'%.3f,%.3f\n',[xN zN]');
    
    fclose(fidw);
    
    
    
end