function [means_total,transitions,rank_means,rank_trans, bar_color] = BAR_CHART(good_transitions, simple_mat, trans_names, complex_mat, bad_transitions, simple_i, complex_i, peptide_name, label, transition_full )
%BAR_CHART takes in many matrices to create a bar chart with the 
%average ratio values for the good and bad transitions, ranks by this value
% and plots as a bar chart with good in black and bad in white
%   The program finds uses the "good" transitions found in the 
%   NON_INT_TRANS function as a denominator and takes the average of 
%   all ratios with this denominator.  This mean is plotted with an error 
%   of +/- stderror.  
%   INPUT: 
%       -good_transitions: cell array with non_int transitions
%       -simple_mat: matrix ratio for simple 
%       -trans_names: cell array transition names (*WITHOUT* zero list)
%       -complex_mat: matrix ratio for complex
%       -bad_transitions: cell array with int transitions
%       -simple_i: array with the simple intensities (trans_names indicate
%       transition).
%       -complex_i: array with the complex intensities (trans_names indicate
%       transition).
%       -peptide_name: string with the following structure
%       Protein_Peptide_Cutoff_Light.png'
%       -label: 'light' or 'heavy'
%       -transition_full:cell array transition names (original *WITH* zero list)
%       -complex_mat: matrix ratio for complex
%   OUTPUT
%       ratio_final: ratio of ratio_complex/ratio_simple (mat)
%       names_new: cell array with transitions with nonzero intensities
%       (array)
%       ratio_simple: permutation matrix for simple (mat)
%       ratio_complex: permutation matrix for complex (mat)

% example variables
%   good_transitions=L1_non_int; 
%   simple_mat=L1_simple ; 
%   trans_names = namesL1; 
%   complex_mat=L1_complex;
%   bad_transitions=L1_int; 
%   simple_i =light_simple;
%   complex_i =light_int;
%   peptide_name=peptide_name;
%   label='Light';
%   transition_full=light_ion;
 
%initialize matrices---------------------------------------------------
LG=length(good_transitions);
LB=length(bad_transitions);
LN=length(trans_names) ;
transitions=good_transitions;
means_good = zeros (LG,2) ;
means_total=zeros(LG+LB,2) ;
LT=LG+LB; 
rank_trans=cell(LT,2); 
bar_color=zeros(LT,1); 

%fix title -------------------------------------------------------------
a=char(peptide_name); 
k=strfind(a,'_'); 
l=strfind(a,'.'); 
name = []; 
for p=1:(k(1)-1)
    c=a(p); 
    name=[name c]; 
end 
name = [name ' ']; 
for p=(k(1)+1):(k(2)-1)
    c=a(p); 
    name=[name c]; 
end 
nameF=name; 

for i=1:LG
    transitions{i,2}='good'; 
end 
transitions(LG+1:LG+LB,1)=bad_transitions(:,1); 
for i=LG+1:LB+LG
    transitions{i,2}='bad'; 
end 
rowN=[]; 

%find the corresponding rows in each matrix ---------------------------
for i=1:LG
    name = good_transitions(i); 
    for j=1:LN
        nameS=trans_names(j); 
        if strcmp(name,nameS)==1 %check if these are equal 
            rowN=[rowN j]; 
        end 
    end      
end 
LNG=length(rowN);

%find the mean in the "good" transitions---------------------------------
for i=1:LG
    S_avg=[]; 
    C_avg=[]; 
    ratio_avg=[];
    indx = rowN(i); 
    for k=1:LNG
        indy=rowN(k); 
        if indx~=indy
            S_avg=[S_avg simple_mat(indx,indy)]; 
            C_avg=[C_avg complex_mat(indx,indy)]; 
            ratio=abs(log2(complex_mat(indx,indy)/simple_mat(indx,indy))); 
            ratio_avg=[ratio_avg ratio]; 
        end  
    end   
    ratio_mean=mean(ratio_avg); 
    ratio_std=std(ratio_avg)/sqrt(LNG); 
    means_good(i,1)=ratio_mean; 
    means_good(i,2)=ratio_std;
%     S_mean = mean(S_avg);
%     S_std = std(S_avg)/sqrt(LNG);  
%     C_mean = mean(C_avg); 
%     C_std = std(C_avg)/sqrt(LNG);  
%     means_good(i,1)= abs(log2(C_mean/S_mean)); 
%     means_good(i,2)= abs(log2(sqrt((S_std/S_mean)^2 + (C_std/C_mean)^2)/sqrt(LNG))); 
    means_total(i,1)=means_good(i,1); 
    means_total(i,2)=means_good(i,2); 
    means_total(i,3)=i; 
end 

 maxG=max(sum(means_good,2)); 
 maxG=maxG+0.25*maxG;
 if maxG==0
     maxG=1; 
 end 

%deal with bad transitions------------------------------------------- 
if isempty(bad_transitions)==0 %make a graph with only the good transitions
    rowNB=[]; 
    means_bad = zeros (LB,2);
    for i=1:LB
        name = bad_transitions(i); 
        check=0; 
        %find the corresponding rows in each matrix 
        for j=1:LN
            nameSB=trans_names(j); 
            if strcmp(name,nameSB)==1 && check==0%check if these are equal 
                rowNB=[rowNB j]; 
                check=1; 
            end 
        end      
    end 
    LNB=length(rowNB) ;
    for l=1:LNB %first find the bad column then the bad row 
        S_avg =[]; 
        C_avg=[]; 
        ratio_avg=[]; 
        indx = rowNB(l);
        for j=1:LNG
            indy = rowN(j); 
            S_avg=[S_avg simple_mat(indx,indy)]; 
            C_avg=[C_avg complex_mat(indx,indy)];
            ratio=abs(log2(complex_mat(indx,indy)/simple_mat(indx,indy))); 
            ratio_avg=[ratio_avg ratio]; 
        end 
        ratio_mean=mean(ratio_avg); 
        ratio_std=std(ratio_avg)/sqrt(LNG); 
        means_bad(l,1)=ratio_mean; 
        means_bad(l,2)=ratio_std; 
%         S_mean =mean(S_avg); 
%         C_mean = mean(C_avg); 
%         S_std = std(S_avg)/sqrt(LNB);  
%         C_std = std(C_avg)/sqrt(LNB);  
%         means_bad(l,1)=abs(log2(C_mean/S_mean)); 
%         means_bad(l,2)= abs(log2(sqrt((S_std/S_mean)^2 + (C_std/C_mean)^2)/sqrt(LNG))); 
         means_total(l+LG,1)=means_bad(l,1); 
         means_total(l+LG,2)=means_bad(l,2); 
         means_total(l+LG,3)=l+LG; 
         maxB=max(sum(means_bad,2)); 
         maxB=maxB+0.25*maxB;
    end
else 
    maxB=0; 
end 
rank_means=sortrows(means_total,1);    
%find the maximum value for the graph------------------------------------
if maxG>=maxB
    maxT = maxG; 
else 
    maxT = maxB; 
end

%run through the transitions and rank them -------------------------------

has_bad=0; 
for i=1:LT; 
    indx=rank_means(i,3);
    rank_trans(i,:)=transitions(indx,:);
    if strcmp(rank_trans(i,2),'good')==1
        bar_color(i,1)=0; 
    else 
        bar_color(i,1)=1; 
        has_bad=1; %indicates has found bad transitions
    end 
    rank_trans(i,:)=transitions(indx,:); 
end 

% %plot subplot with good transitions (in black) and bad transitions in white
% %ranked by the average ratio values --------------------------------------
% figure;  
% bh=bar(rank_means(:,1)); 
% ch=get(bh,'Children');  
% set (ch,'CData',bar_color) ; 
% if has_bad==1
%     colormap(gray); 
% else 
%     set(gcf, 'ColorMap', [0,0,0; 0,0,0])
%     %colormap(black); 
% end 
% hold on 
% errorbar (rank_means(:,1), rank_means(:,2), 'xb'); 
% xlabel ('transition', 'FontSize',14); 
% ylabel ('mean transition ratio (abs(log2(ratio))', 'FontSize',18); 
%  ylim([0,maxT]); 
%  xlim([0,LT+1]);
% %fix x-axis
% set (gca, 'XMinorTick','on'); 
% set (gca,'xtick',1:LT);
% set (gca, 'XTickLabel',rank_trans, 'fontsize',14); 
% rotateXLabels(gca,45);
% %title([nameF ' ' label]); 
% hold off
% print (gcf,'-dpdf', ['bar_' peptide_name '.pdf'] );

% %add subplot with intensity values within graph as scatter-----------------
% %find the intensity for each transition (use rank_trans) 
% LR=length(rank_trans); 
% rank_simple=zeros(LR,1);
% rank_complex=zeros(LR,1);
% 
% sum_simple=sum(simple_i); 
% sum_complex=sum(complex_i); 
% for i=1:LR
%     name=rank_trans(i,1);
%     indx=find(strcmp(name,transition_full(:,1))==1); %find same transition
%     if isempty(indx)==0
%         rank_simple(i)=simple_i(indx,1);%/sum_simple*100; 
%         rank_complex(i)=complex_i(indx,1);%/sum_complex*100; 
%     end
% end 
%  maxS=max(rank_simple); 
%  maxS=maxS+0.25*maxS; 
%  maxC=max(rank_complex); 
%  maxC=maxC+0.25*maxC; 
%  %maxY=max(maxC,maxS); 
% 
% x=1:LR; 
% figure; 
% f1=subplot(3,1,1); 
% bh=bar(rank_means(:,1)); 
% ch=get(bh,'Children');  
% set (ch,'CData',bar_color) ; 
% if has_bad==1
%     colormap(gray); 
% else 
%     set(gcf, 'ColorMap', [0,0,0; 0,0,0])
%     %colormap(black); 
% end 
% hold on 
% errorbar (rank_means(:,1), rank_means(:,2), 'xb');
% title([nameF ' ' label]);
% ylabel ('mean transition ratio (abs(log2(ratio))','FontSize',11); 
% hold off
% set (f1, 'XTickLabel',[]); 
% set (f1, 'XTick',[]); 
% set (gca, 'FontSize',10); 
% xlim([0 LR+1]);
% ylim([0,maxT]); 
% 
% f2=subplot(3,1,2);
% bar(rank_simple(:,1),'b'); 
% ylabel ('simple intensity','FontSize',11); 
% set (f2, 'XTickLabel',[]); 
% set (f2, 'XTick',[]); 
% set (gca, 'FontSize',6); 
%  xlim([0 LR+1]);
%  ylim([0 maxS]); 
%  
% f3=subplot(3,1,3);
% bar (rank_complex(:,1),'g'); 
% xlabel ('transition'); 
% ylabel ('complex intensity','FontSize',11); 
%  %ylim([0,maxT]); 
%  xlim([0 LR+1]);
%  ylim([0 maxC]); 
%  
% %fix x-axis
% %set (gca, 'XMinorTick','on'); 
% set (gca,'xtick',x);
% %set (f3, 'YTickLabel', 'fontsize',6); 
% set (gca, 'FontSize',6); 
% set (gca, 'XTickLabel',rank_trans (:,1), 'FontSize',11); 
% rotateXLabels(gca,45);
% %title([nameF ' ' label]); 
% 
% %link axes 
% %linkaxes([f1 f2 f3],'x'); 
% pos1=get(f1,'Position'); 
% pos2=get(f2,'Position');
% pos3=get(f3,'Position');
% %set the width equal in all 
%  pos2(3)=pos1(3); 
%  pos3(3)=pos1(3); 
%  set(f2,'Position',pos2); 
%  set(f3,'Position',pos3); 
% %move the second up to touch the first 
% pos2(2)=pos1(2)-pos2(4); 
% set(f2,'Position',pos2); 
% pos3(2)=pos2(2)-pos3(4); 
% set (f3,'Position',pos3); 
% 
% print (gcf,'-dpdf', ['bar_int_' peptide_name '.pdf'] );
% close all; 


end

