function [ratio_H1_log4, ratio_L1_log4, namesH1, namesL1 ] = Run_CRAFTS( light_int, heavy_int, light_simple, heavy_simple, light_ion, heavy_ion, cutoff, protein_name)

cd Functions 
cutoffT=num2str(cutoff); 
font=10; 
font_big=font+4; 
cmax=1; 
cmin=-1; 
[ratio_L1, namesL1, L1_simple, L1_complex]=FIND_RATIO(light_simple, light_int, light_ion); 
xlab=namesL1 ;
ratio_L1_log=log2(ratio_L1); 
num_dig=2; 
n=ratio_L1_log; 
ratio_L1_log4=round(n*(10^num_dig))/(10^num_dig);
h=heatmap_rb(ratio_L1_log4,xlab,xlab,1,cmax,cmin,'Colormap','money','Colorbar',1,'TickAngle',90,'ShowAllTicks',1,'FontSize',font, 'TickFontSize', font); 
print (gcf, '-dpdf', [protein_name 'light_heatmap_rb.pdf']);
h=heatmap_rb(ratio_L1_log4,xlab,xlab,[],cmax,cmin,'Colormap','money','Colorbar',1,'TickAngle',90,'ShowAllTicks',1, 'TickFontSize', font); 
print (gcf, '-dpdf', [protein_name 'light_heatmap_rb_nonum.pdf']);

 peptide_name=[char(protein_name) '_' cutoffT '_Light.pdf']; 
[L1_non_int, L1_int]=FIND_INT(ratio_L1, namesL1, peptide_name, cutoff, 'Light'); 
[L1_total, L1_trans_new,L1_rank_means, L1_rank_trans, L1_bar_color]=BAR_CHART(L1_non_int, L1_simple, namesL1, L1_complex, L1_int, light_simple, light_int, peptide_name, 'Light',light_ion); 

[ratio_H1, namesH1,H1_simple, H1_complex]=FIND_RATIO(heavy_simple, heavy_int,heavy_ion); 
xlab=namesH1; 
ratio_H1_log=log2(ratio_H1); 
num_dig=2; 
n=ratio_H1_log; 
ratio_H1_log4=round(n*(10^num_dig))/(10^num_dig);
h=heatmap_rb(ratio_H1_log4,xlab,xlab,1,cmax,cmin,'Colormap','money','Colorbar',1,'TickAngle',90,'ShowAllTicks',1,'FontSize',font, 'TickFontSize', font); 
print (gcf, '-dpdf', [protein_name 'heavy_heatmap_rb.pdf']);

h=heatmap_rb(ratio_H1_log4,xlab,xlab,[],cmax,cmin,'Colormap','money','Colorbar',1,'TickAngle',90,'ShowAllTicks',1,'TickFontSize', font); 
print (gcf, '-dpdf', [protein_name 'heavy_heatmap_rb_nonum.pdf']);
close all ;

peptide_nameH=[char(protein_name) '_' cutoffT '_Heavy.pdf']; 
[H1_non_int, H1_int]=FIND_INT(ratio_H1, namesH1,peptide_nameH, cutoff, 'Heavy');
[H1_total, H1_trans_new,H1_rank_means, H1_rank_trans, H1_bar_color]=BAR_CHART(H1_non_int, H1_simple, namesH1, H1_complex, H1_int,heavy_simple, heavy_int, peptide_nameH, 'Heavy', heavy_ion); 

%make bar chart with the same y axis limits--------------------------------
%find max for rank_means (:,2)

total_L=L1_rank_means(:,1)+L1_rank_means(:,2); 
total_H=H1_rank_means(:,1)+H1_rank_means(:,2); 
maxL=max(total_L); 
maxH=max(total_H); 
maxY=max(maxL,maxH); 
ylimit=maxY+0.1*maxY; 
LT=length(L1_rank_trans); 
J=find(L1_bar_color(:,1)>0); 
if isempty(J)==1
    has_bad=0; 
else 
    has_bad=1; 
end 


%LIGHT PLOT 
bh=bar(L1_rank_means(:,1)); 
ch=get(bh,'Children');  
set (ch,'CData',L1_bar_color) ; 
if has_bad==1
    colormap(gray); 
else 
    set(gcf, 'ColorMap', [0,0,0; 0,0,0])
    %colormap(black); 
end 
hold on 
errorbar (L1_rank_means(:,1), L1_rank_means(:,2), 'xb'); 
xlabel ('transition', 'FontSize',font_big); 
ylabel ('mean transition ratio (abs(log2(ratio))', 'FontSize',font_big); 
 ylim([0,ylimit]); 
 xlim([0,LT+1]);
%fix x-axis
set (gca, 'XMinorTick','on'); 
set (gca,'xtick',1:LT);
set (gca, 'XTickLabel',L1_rank_trans, 'fontsize',font); 
rotateXLabels(gca,45);
%title([nameF ' ' label]); 
hold off
print (gcf,'-dpdf', ['bar_LIGHT' peptide_name '.pdf'] );

%HEAVY PLOT 
J=find(H1_bar_color(:,1)>0); 
if isempty(J)==1
    has_bad=0; 
else 
    has_bad=1; 
end 
LT=length(H1_rank_trans);
bh=bar(H1_rank_means(:,1)); 
ch=get(bh,'Children');  
set (ch,'CData',H1_bar_color) ; 
if has_bad==1
    colormap(gray); 
else 
    set(gcf, 'ColorMap', [0,0,0; 0,0,0])
    %colormap(black); 
end 
hold on 
errorbar (H1_rank_means(:,1), H1_rank_means(:,2), 'xb'); 
xlabel ('transition', 'FontSize',font_big); 
ylabel ('mean transition ratio (abs(log2(ratio))', 'FontSize',font_big); 
 ylim([0,ylimit]); 
 xlim([0,LT+1]);
%fix x-axis
set (gca, 'XMinorTick','on'); 
set (gca,'xtick',1:LT);
set (gca, 'XTickLabel',H1_rank_trans, 'fontsize',font); 
rotateXLabels(gca,45);
%title([nameF ' ' label]); 
hold off
print (gcf,'-dpdf', ['bar_HEAVY' peptide_nameH '.pdf'] );



[int_mat_S, rank_trans_S]=CAL_CURVE_RATIO(L1_rank_trans, H1_rank_trans, L1_rank_means, H1_rank_means, light_simple, heavy_simple, light_ion,heavy_ion, ['simple_' cutoffT]); 
[int_mat_C, rank_trans_C]=CAL_CURVE_RATIO(L1_rank_trans, H1_rank_trans, L1_rank_means, H1_rank_means, light_int,   heavy_int, light_ion,heavy_ion, ['complex' cutoffT]); 

[ A ] = PAR( int_mat_S,int_mat_C,rank_trans_C, peptide_name,light_int, heavy_int, light_ion, cutoff );

end

