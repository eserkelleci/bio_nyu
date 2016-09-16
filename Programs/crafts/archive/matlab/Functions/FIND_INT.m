function [ trans_names_non_int, trans_names_int ] = FIND_INT(ratio_mat, trans_names, peptide_name, cutoff, label )
%FIND_INT (versions called MSlist_ratiov2) takes in the ratio matrix, transition names 
%and a cutoff to find the transitions with interference.  Also creates 
%a heatmap displaying which relationships are below the cutoff value 
%   INPUT: 
%       -ratio_mat: ratio of ratio_complex/ratio_simple (mat)
%       -trans_names: cell array with transitions with nonzero intensities
%       (array)
%       -peptide_name: string with the following structure
%       Protein_Peptide_Cutoff_Light.png'
%       -cutoff: cutoff threshold (between 0 and 1)
%       -label: Light or Heavy
%   OUTPUT
%       -trans_names_non_int: list of transition names without interference
%       -trans_names_int: list of transitions with interference

% %variable examples: 
% ratio_mat=ratio_L1;
% trans_names=namesL1;
% peptide_name='test_2';
% cutoff=0.10; 
% label='Light';

%-----------------initialize variables------------------------------------
ratio_matF=abs(log10(ratio_mat)); 
[r,c]=size(ratio_matF);  
ratio_matF2=ratio_matF; 

%-----------------manipulate matrix for pcolor graph-----------------------
for i=1:r
    ratio_matF2(i,i)=5; %put value of 5 across the diagnal
end 
ratio_matF3=ratio_matF2; %keep this and use it later when making the bar charts 
ratio_matF2(r+1,:)=0; 
ratio_matF2(:,r+1)=0; 
ratio_matF2((ratio_matF2)<=cutoff)=0;  %good values 
ratio_matF2((ratio_matF2)>cutoff)=10; %bad values

%-----------------alter title to look better------------------------------
a=char(peptide_name); 
k=strfind(a,'_'); 
l=strfind(a,'.'); 
name = []; 
for p=1:(k(1)-1)
    c=a(p); 
    name=[name c]; 
end  
nameF=name; 

%-----------------plot at color map (pcolor)------------------------------
map = [1 0 0; 0 0 0; 1 1 1]; 
if numel(ratio_matF2)>0
    h=figure; 
    pcolor(ratio_matF2); 
    colormap (map); 
   % title([nameF ' ' label]); 
    set (gca, 'XMinorTick','on','YMinorTick','on'); 
    set (gca,'ytick',1:r,'xtick',1:r); 
    set (gca,'FontSize',20) %, 'FontName', 'Helvtica'); 
    set (gca, 'YTickLabel',trans_names); 
    set (gca, 'XTickLabel', trans_names); 
    %rotate and move X labels
    ax=gca; 
    xpos=get(ax,'Xtick'); 
    set (gca,'XMinorTick','on','XTickLabel',[]); 
    xpos2=xpos+0.5; 
    set(ax,'XMinorTick','on','Xtick',xpos2); 
    set (gca, 'XTickLabel', trans_names); 
    rotateXLabels(gca,90);
    % move Y labels
    ay=gca; 
    ypos=get(ay,'Ytick'); 
    set (gca,'YMinorTick','on','YTickLabel',[]); 
    ypos2=ypos+0.5; 
    set(ax,'YMinorTick','on','Ytick',ypos2); 
    set (gca, 'YTickLabel', trans_names); 
    print (gcf,'-dpdf', ['pcolor_' peptide_name '.pdf'] );
    close all; 
    %---------Determine interferences-----------------------------------------
    [trans_names_non_int, trans_names_int]= NON_INT_TRANS(ratio_matF3, trans_names, cutoff);
    trans_names_non_int=trans_names_non_int';  
    cell2csv(['trans_non_int_' nameF], trans_names_non_int, '\t'); 
else 
    trans_names_non_int=[]; 
    trans_names_int=[]; 
end 
end

