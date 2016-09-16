function [A] = PAR_nosum(  light_trans_rank, heavy_trans_rank,  light_S, heavy_S, light_C, heavy_C,transitions_oldL, transitions_oldH, label )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%make a matrix with the PAR for each of the intensity combinations and plot
%as scatter plot 
%  light_trans_rank=L1_trans_new; 
%  heavy_trans_rank=H1_trans_new; 
%  heavy_S=heavy_simple; 
%  light_S=light_simple; 
%  heavy_C=heavy_int; 
%  light_C=light_int; 
%  transitions_oldL=light_ion; 
%  transitions_oldH=heavy_ion; 
%  label ='AKT-10_simple'; 
 

%find new rank by averaging the H/L ranks and then finding the best ones
%from there 
rank_final=double.empty; 
rank_final_cell=cell.empty; 
m=1; 

for i=1:length(light_trans_rank)
    indx=''; 
    name=light_trans_rank(i,1) ;
    good=light_trans_rank(i,2); 
    if strcmp(good,'good')==1
        indx=find(strcmp(heavy_trans_rank(:,1),name)==1);
        %indx=cell2num(indx)
        if (isempty(indx)==0)
            if strcmp(heavy_trans_rank(indx(1),2),'good')==1
                rank_new = (i+indx(1))/2 ; 
                rank_final_cell(m,1)=name ;
                rank_final(m,1)=rank_new ;
                rank_final(m,2)=m; 
                m=m+1; 
            end 
        end 
    end 
end 

%reorder the transitions
rank_final2=sortrows(rank_final) ;
Lmatrix_plot=zeros(length(rank_final2),1); 
rank_final_cell2=cell(length(rank_final),1); 
m=1; 
num_=0; 

for i=1:length(rank_final2)
    indx=rank_final2(i,2); 
    rank_final_cell2(i,1)=rank_final_cell(indx,1); 
end 

%simple
h_int=0; 
l_int=0; 
y=1:length(rank_final2); 
for i=1:length(rank_final2)
    name=rank_final_cell2(i,1);
    indx=find(strcmp(transitions_oldL(:,1),name)==1); %find the same transition in old 
    indxH=find(strcmp(transitions_oldH(:,1),name)==1); 
%     h_int=h_int+heavy(indxH,1); 
%     l_int=l_int+light(indx,1); 
    %peak_int=l_int/h_int; 
    peak_int_alone=light_S(indx,1)/heavy_S(indxH,1); 
    Lmatrix_plot(i,1)=peak_int_alone;
end 

%complex
h_int=0; 
l_int=0; 
y=1:length(rank_final2); 
for i=1:length(rank_final2)
    name=rank_final_cell2(i,1);
    indx=find(strcmp(transitions_oldL(:,1),name)==1); %find the same transition in old 
    indxH=find(strcmp(transitions_oldH(:,1),name)==1); 
%     h_int=h_int+heavy(indxH,1); 
%     l_int=l_int+light(indx,1); 
    %peak_int=l_int/h_int; 
    peak_int_alone=light_C(indx,1)/heavy_C(indxH,1); 
    Lmatrix_plot(i,2)=peak_int_alone;
end 

%PLOT THE COMBINATION of light/heavy ----------------------------------
maxT=max(Lmatrix_plot(:));  
maxT=maxT+0.1*maxT; 
scatter(y,Lmatrix_plot(:,1),'*k'); 
hold on 
scatter (y,Lmatrix_plot(:,2), '*b'); 
hold off; 
ylabel ('peak area ratio (light/heavy)'); 
xlabel ('transition ranking'); 
ylim([0 maxT]); 
xlim([0 (length(rank_final2)+1)]); 
set (gca,'xtick',1:(length(rank_final2)));
set (gca, 'XTickLabel',rank_final_cell2);  
%set (gca, 'XMinorTick','on','YMinorTick','on'); 
set (gca,'FontSize',8, 'FontName', 'Helvtica');
rotateXLabels(gca,45);
title(label); 

print (gcf,'-dpng', ['PAR_nosum' label] );

A=1; 

end

