function [array_plot,rank_final_cell] = CAL_CURVE_RATIO(  light_trans_rank, heavy_trans_rank, light_rank_means, heavy_rank_means,  light, heavy, transitions_oldL, transitions_oldH, label )
%Cal_Curve takes in the new ranked transitions based on ratio for both
%heavy and light, the heavy and light intensity values and the transitions
%for the heavy and light ions and makes a ratio of light/heavy graphed
%   INPUT: 
%       -light_trans_rank: cell array ranked transitions for light (by avg ratio)
%       -heavy_trans_rank: cell array ranked transitions for heavy (by avg ratio)
%       -light_rank_means: matrix with ranked means (:,1), stdev (:,2),
%       rank 
%       -heavy_rank_means: matrix with ranked means (:,1), stdev (:,2),
%       rank
%       -light: intensity values for light transitions
%       -heavy: intensity values for heavy transitions
%       -transitions_oldL: old cell array of transitions light
%       -transitions_oldH: old cell array of transitions heavy
%       -label: label to use for title
%   OUTPUT
%       -array_plot: matrix of intensity ratios of light over heavy the
%       first column has the summed values, so for each additional
%       transition we add the intensity values for light trans1+trans2+...
%       over heavy trans1+trans2+.... for the second column its the
%       intensity for JUST that transition alone.  The first column is used
%       for the plot 
%       -rank_final_cell2: the new ranks taking into account ratio values
%       for both heavy and light 

%variable examples: 
%   light_trans_rank=L1_trans_new; 
%   heavy_trans_rank=H1_trans_new;
%   light_rank_means=L1_rank_means; 
%   heavy_rank_means=H1_rank_means; 
%   heavy=heavy_int; 
%   light=light_int; 
%   transitions_oldL=light_ion; 
%   transitions_oldH=heavy_ion; 
%   label ='TEST';   
  
%------------initialize variables----------------------------------------
rank_cell=cell.empty; 
rank_final_cell=cell.empty; 
means_new=double.empty; 
m=1;

%------average H,L  means to find new transition ranking-------------------
for i=1:length(light_trans_rank) %'i' is the light index 
    name=light_trans_rank(i,1) ;
    indx=find(strcmp(heavy_trans_rank(:,1),name)==1); %find the index in heavy 
    if (isempty(indx)==0) %as long as index is there 
        meanL=light_rank_means(i,1); 
        meanH=heavy_rank_means(indx,1); 
        means_new(m,1) = (meanL+meanH)/2 ; %new means for heavy and light 
        means_new(m,2)=m; 
        rank_cell(m,1)=name ;
        m=m+1; 
    end 
end 
rank_final=sortrows(means_new,1); 
[r,c]=size(rank_final); 

%----------------------rank transition names to match rank_final----------
for i=1:r;
    indx=rank_final(i,2); 
    rank_final_cell(i,1)=rank_cell(indx,1); 
end 


%-------------find the intensity ratios for each---------------------------
array_plot=zeros(r,1); 
h_int=0; 
l_int=0; 
y=1:r; 

for i=1:r
    name=rank_final_cell(i,1); %transition for new 
    indx=find(strcmp(transitions_oldL(:,1),name)==1); %find the same transition in old 
    indxH=find(strcmp(transitions_oldH(:,1),name)==1); 
    h_int=h_int+heavy(indxH,1); 
    l_int=l_int+light(indx,1); 
    peak_int=l_int/h_int; 
    peak_int_alone=light(indx,1)/heavy(indxH,1); 
    array_plot(i,1)=peak_int;
    array_plot(i,2)=peak_int_alone; 
end 

%-----------plot graph--------------------------------------------------
% maxT=max(array_plot(:,1));  
% maxT=maxT+0.1*maxT; 
% minT=min(array_plot(:,1)); 
% minT=minT-0.1*minT; 
% scatter(y,array_plot(:,1),'*b'); 
% ylabel ('peak area ratio (light/heavy)'); 
% xlabel ('transition ranking'); 
% set (gca, 'XTickLabel',rank_final_cell);  
% %set (gca, 'XMinorTick','on','YMinorTick','on'); 
% set (gca,'ytick',1:r,'xtick',1:r);
% set (gca,'FontSize',11);
% rotateXLabels(gca,45);
% title(label); 
% ylim([minT maxT]); 
% print (gcf,'-dpdf', ['PAR_' label '.pdf'] );
% 
% %-----------plot individual graph----------------------------------------
% maxT=max(array_plot(:,2));  
% maxT=maxT+0.1*maxT; 
% minT=min(array_plot(:,2)); 
% minT=minT-0.1*minT; 
% scatter(y,array_plot(:,2),'*b'); 
% ylabel ('peak area ratio (light/heavy)'); 
% xlabel ('transition ranking'); 
% set (gca, 'XTickLabel',rank_final_cell);  
% %set (gca, 'XMinorTick','on','YMinorTick','on'); 
% set (gca,'ytick',1:r,'xtick',1:r);
% set (gca,'FontSize',11, 'FontName', 'Helvtica');
% rotateXLabels(gca,45);
% title(label); 
% ylim([minT maxT]); 
% print (gcf,'-dpdf', ['PAR_individual' label '.pdf'] );
% 
% A=1; 

end

