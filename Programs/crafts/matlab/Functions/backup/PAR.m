function [ A ] = PAR( int_mat_S,int_mat_C,rank_trans_C,peptide_name,light_int,   heavy_int, transition_full, threshold )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
 %plot the combination of simple and complex- with interferences added 
    
% %example variables: 
% int_mat_S=int_mat_S; 
% int_mat_C=int_mat_C; 
% rank_trans_C=rank_trans_C; 
% peptide_name=peptide_name; 
% light_int=light_int; 
% heavy_int=heavy_int; 
% transition_full=light_ion; 
% threshold=0.1; 
%     
%add subplot with intensity values within graph as scatter-----------------
%find the intensity for each transition (use rank_trans_C) 
LR=length(rank_trans_C); 
rank_light=zeros(LR,1);
rank_heavy=zeros(LR,1);
format long; 

for i=1:LR
    name=rank_trans_C(i,1); 
    indx=find(strcmp(name,transition_full(:,1))==1); %find same transition
    rank_light(i)=light_int(indx,1)/10000;
    rank_heavy(i)=heavy_int(indx,1)/10000; 
end 
 maxL=max(rank_light); 
 maxL=maxL+0.25*maxL; 
 maxH=max(rank_heavy); 
 maxH=maxH+0.25*maxH; 
 %maxY=max(maxC,maxS); 
 stopped=length(int_mat_C); 
 
 start_complex=int_mat_C(1,1); 
 start_min= int_mat_C(1,1)-int_mat_C(1,1)*threshold; 
 start_max= int_mat_C(1,1)+int_mat_C(1,1)*threshold; 
 stop=0; 
 for i=1:length(int_mat_C); 
     relative=abs(int_mat_C(1,1)-int_mat_C(i,1))/int_mat_C(1,1); 
    if relative <= threshold && stop==0
        stopped=i; 
    else 
        stop=1; 
    end 
 end 

x=1:LR; 
x2=[0 10000]; 
y2=[stopped stopped]; 
figure; 
f1=subplot(7,1,[1 2 3]); 
    maxS=max(int_mat_S(:,1)); 
    maxC=max(int_mat_C(:,1)); 
    minS=min(int_mat_S(:,1)); 
    minC=min(int_mat_C(:,1)); 
    maxT=max(maxS,maxC); 
    maxT=maxT+0.1*maxT; 
    minT=min(minS,minC); 
    minT=minT-0.1*minT; 
    maxI=max(maxL, maxH); 
    factor=ceil(maxI/100000); 
    fact_F=(factor-2)*100000; 
    
   y=1:length(rank_trans_C); 
    plot(y,int_mat_S(:,1),'-*k');
    %plot (x,start_max,'--r'); 
    hold on
    %plot (x,start_min,'--r'); 
    plot(y,int_mat_C(:,1),'-*b');  
    plot (y2,x2,'-r'); 
    ylim([0 maxT]); 
    xlim([0 (LR+1)]);
    set (f1, 'XTick',[]);
    set (gca, 'FontSize',14); 
    ylabel ('PAR (Light/Heavy)','FontSize',14); 
    AX=legend('Simple','Complex','Location','SouthEast'); 
    LEG = findobj(AX,'type','text');
    set(LEG,'FontSize',16)
    hold off 
    
f2=subplot(7,1,[4 5]);
    bar(rank_light(:,1),'b'); 
    set (f2, 'XTickLabel',[]); 
    set (f2, 'XTick',[]); 
    set (gca, 'FontSize',14); 
    ylabel ('Light (10^4)','FontSize',14); 
    %set (gca, 'YTickLabel', 'FontSize',8);
    xlim([0 LR+1]);
    ylim([0 maxL]); 
   %set (f2, 'YTick',0:100000:fact_F); 
 
f3=subplot(7,1,[6 7]);
    bar (rank_heavy(:,1),'r'); 
    set (gca, 'FontSize',14); 
    %set (gca, 'YTickLabel', 'FontSize',11); 
    ylabel ('Heavy (10^4)','FontSize',14); 
    xlabel ('Transition', 'FontSize', 14); 
    %ylim([0,maxT]); 
    xlim([0 LR+1]);
    ylim([0 maxH]); 
    %set (f3, 'YTick',0:100000:fact_F); 
 
%fix x-axis
    set (gca, 'XMinorTick','on'); 
    set (gca,'xtick',x);
    %set (f3, 'YTickLabel', 'fontsize',6); 
    %set (gca, 'FontSize',11); 
    %set (gca, 'YTickLabel', 'FontSize',8);
    set (gca, 'XTickLabel',rank_trans_C (:,1)) 
    xlhand = get(gca,'xlabel');
    set(xlhand,'fontsize',18);
    rotateXLabels(gca,45);
    %title([nameF ' ' label]); 

%link axes 
    %linkaxes([f1 f2 f3],'x'); 
    pos1=get(f1,'Position'); 
    pos2=get(f2,'Position');
    pos3=get(f3,'Position');
    %set the width equal in all 
    pos2(3)=pos1(3); 
    pos3(3)=pos1(3); 
    set(f2,'Position',pos2); 
    set(f3,'Position',pos3); 
    %move the second up to touch the first 
    pos2(2)=pos1(2)-pos2(4); 
    set(f2,'Position',pos2); 
    pos3(2)=pos2(2)-pos3(4); 
    set (f3,'Position',pos3); 

print (gcf,'-dpdf', ['PAR_bar_int_' peptide_name '.pdf'] );
close all;  

A=1; 

end

