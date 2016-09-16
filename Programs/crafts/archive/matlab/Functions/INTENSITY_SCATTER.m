function [ A ] = INTENSITY_SCATTER( means_totalL, transitions_newL, simpleL, complexL, means_totalH, transitions_newH, simpleH, complexH,transitions,nameF )
%INTENSITY_SCATTER takes in the intensity values, ratio means for simple,
%complex, heavy, light and plots them on a graph of ratio vs. intensity
%   INPUT: 
%       -means_totalL: matrix with ranked means (:,1), stdev (:,2),
%       rank (:,3)
%       -transitions_newL: transition list associated with means_totalL
%       -simpleL: intensity values for light-simple
%       -complexL: intensity values for light-complex
%       -means_totalH: matrix with ranked means (:,1), stdev (:,2),
%       rank (:,3)
%       -transitions_newH: transition list associated with means_totalH
%       -simpleH: intensity values for heavy-simple
%       -complexH: intensity values for heavy-complex
%       -transitions: transition list associated with intensity arrays
%       -nameF: name to use for a label
%   OUTPUT
%       -A: stand in output (always 1).  creates and saves graph

%---------initialize variables----------------------------------------
S_L=double.empty; 
C_L=double.empty; 
S_H=double.empty; 
C_H=double.empty;  
t_L=cell.empty; 
t_H=cell.empty; 


%-----make ratio/intensity matrix for the 4 conditions---------------------
m=1; 
for i=1:length(transitions_newL)
    indx=0; 
    name=transitions_newL(i,1);
    k=[]; 
    k=strfind(name,'-') ;
    if isempty(k{1})==1 %only look at ions without neutral losses 
        indx=find(strcmp(transitions(:,1),name)==1); %find the same transition
        if indx~=0
            indx2=indx;  %NEED TO CHANGE THIS IF WE HAVE A HEADER! 
            S_L(m,1)=log2(simpleL(indx2,1)); 
            S_L(m,2)=means_totalL(i,1); 
            C_L(m,1)=log2(complexL(indx2,1)); 
            C_L(m,2)=means_totalL(i,1);
            t_L(m,1)=transitions_newL(i,1); 
            m=m+1; 
        end 
    end 
end 
m=1; 
for i=2:length(transitions_newH)
    indx=0; 
    name=transitions_newH(i,1); 
    k=[]; 
    k=strfind(name,'-') ;
    if isempty(k{1})==1
        indx=find(strcmp(transitions(:,1),name)==1); %find the same transition
        if indx~=0
            indx2=indx; 
            S_H(m,1)=log2(simpleH(indx2,1)); 
            S_H(m,2)=means_totalH(i,1); 
            C_H(m,1)=log2(complexH(indx2,1)); 
            C_H(m,2)=means_totalH(i,1);
            t_H(m,1)=transitions_newH(i,1); 
            m=m+1; 
        end
    end 
end 
A=1; 

%--------------------create graph--------------------------------------
lscatter (S_L(:,2),S_L(:,1),t_L(:,1),'FontSize',8,'TextColor','blue'); 
hold on; 
lscatter (C_L(:,2),C_L(:,1),t_L(:,1),'FontSize',8,'TextColor','black');
lscatter (S_H(:,2),S_H(:,1),t_H(:,1),'FontSize',8,'TextColor','red'); 
lscatter (C_H(:,2),C_H(:,1),t_H(:,1),'FontSize',8,'TextColor','magenta');
xlabel ('mean transition ratio (log2)'); 
ylabel ('peak intensity (log2)'); 
title(nameF); 
hold off; 
print (gcf,'-dpdf', ['scatter_' nameF '.pdf'] );
close all; 
end

