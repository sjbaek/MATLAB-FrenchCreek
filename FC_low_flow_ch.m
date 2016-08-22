clear all
close all

% changing channel geometry
% Low Flow channel configuration: French Creek
% 10/22/2015, sjb

cd('C:\Works\032430.A0 French Creek\NHC model\18b\Transects_Element_1')
tr_name = '10746_23';
file_name = sprintf('TR_%s.txt',tr_name);
fid = fopen(file_name);
C = textscan(fid,'%f%f','delimiter','\t','headerlines',1);

x = C{1}; z = C{2};
[zC, Ith] = min(z);  % identify lowest point value and index: z(Ith) = zC
xC = x(Ith);         % x at thalweg (xC)



%%
plot(x,z,'.-')
% 1) delete z < 4.3' from existing
% 2) check the existing width at z = 4.3 is greater than proposed width
%    new width at bench: 4*(4.3-zc) + bWid
%       bWid = bottom width
%       zc = thalweg elevation

%% new (narrow) channel geometry: trapezoidal shape
zB = 4.3;  % zB: elevation of Bench
bWid = 10; % bottom width

zNew = [zB zC zC zB];
x1 = xC-(2*(zB-zC)+bWid/2);
x2 = xC+(2*(zB-zC)+bWid/2);
xNew = [x1 xC-bWid/2 xC+bWid/2 x2];

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
xN = [xL; v_LBank; xNew'; v_RBank; xR];
zN = [zL; z_bankL; zNew'; z_bankR; zR];
hold on
plot(xN,zN,'r.-')
grid

%% writing out new x-z transects
