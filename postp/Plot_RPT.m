clear all; close all;
% This script converts results from EQquasi to rupture.dat and plots it.
% Change log:
% 20220812: add plots for other components.
% 20210410: make the script more flexible with different dx and path setup. 

% Data structure of cplot_EQquasi.txt.
% Col:
% 1, 2, 3,   4,     5, 6, 7, 8, 9, 
% x, z, slr, theta, ts,td,tn
ht = 2; hs = 2; H = 12; 
mod = 1001;
ic = 2;
col = 16; 

[path,dx,nzz,l] = model_info(mod)

out = strcat(path,'res/rupture.dat');
header = 'header/rptheader.txt';

path1 = strcat(path,'Q',num2str(ic-1),'/')
a = load(strcat(path1,'cplot_EQquasi.txt'));
tt = load(strcat(path1,'tdyna.txt'));

x = -l:dx:l;
z = -l:dx:0;
zcenter = 0;
% if mod == 12
%     z=-2*l:dx:0;
%     zcenter = -60;
% end
[xx,zz] =meshgrid(x,z);
[nz,nx] = size(xx);
ntag = 0; 
for i = 1:nx
    for j =1:nz
        if col == 16
            rpt(j,i) = a((i-1)*nzz+j,16)-tt(1,1);
            if rpt(j,i)<0
                rpt(j,i) = 1e4;
            end
            if (abs(xx(j,i))<= l/2+2*ht && abs(zz(j,i)-zcenter)<= H +2*ht +hs )
                ntag = ntag + 1;
                rptout(ntag,1) = xx(j,i)*1e3;
                rptout(ntag,2) = -(zz(j,i))*1e3;
                rptout(ntag,3) = rpt(j,i);
            end
        else 
            rpt(j,i) = a((i-1)*nzz+j,col)/1e6;
        end
    end
end

ll = 0:10:300;
figure(1)
if col == 16
    contour(xx,zz,rpt,ll, 'ShowText' ,'on');colorbar;axis equal;hold on;
    delete(out);
    %%output the combined file
    fileID = fopen('a','w');
    fprintf(fileID,'%22.14e %22.14e %22.14e \n',rptout(:,:)');
    fclose(fileID);
    system(strcat('type'," ",'.\header\rptheader.txt'," ",'>>'," ",out));
    system(strcat('type'," ",'a'," ",'>>'," ",out));
else
    contourf(xx,zz,rpt);colorbar;axis equal;hold on;
end
