function [ tran_names_non_int, tran_names_int ] = NON_INT_TRANS( log_mat, tran_names, cut_off )
%NON_INT_TRANSITIONS: function uses the ratio matrix (LOG_MAT) coming from 
%   the RATIO_FIND.m function (plus a log normalization) and a list of the
%	transitions in the matrix  (TRAN_NAMES) and outputs a list of the final 
%   transitions to use (with the lowest interference) as NON_INT_LIST and
%   their associated names TRAN_NAMES_FINAL.  The INT_LIST has the
%   transitions that did not make the cut off and the TRAN_NAMES_INT are
%   the names associated with this trations.  The CUTOFF can be changed but
%   we use between 0.15 and 0.2.  
%   INPUT: 
%       log_mat: log10 ratio of ratio_complex/ratio_simple (mat)
%       trans_names: cell array with transitions with nonzero intensities
%       (array)
%       peptide_name: string with the following structure
%       Protein_Peptide_Cutoff_Light.png'
%       cutoff: cutoff threshold (between 0 and 1)
%       label: Light or Heavy
%   OUTPUT
%       trans_names_non_int: list of transition names without interference
%       trans_names_int: list of transitions with interference


%------initialize values--------------------------------------------------
[r,c]=size(log_mat); 
trans1=0; 
trans2=0; 
minimum = 1; 


%--------find minimum in matrix--------------------------------------------
for i=1:r
    for j=1:c
        min_temp = log_mat(i,j); 
            if min_temp < minimum
                minimum = min_temp; %minimum value in matrix
                trans1=i; %keeps the location of value stored to use later
                trans2=j; 
            end 
    end 
end 

%run through the matrix to find values in minimum row/column below cutoff-
non_int_list = [trans1 trans2]; 
column_list = trans2; 
for i=1:r
    ratio = log_mat (i, trans2); 
    if ratio <= cut_off
        non_int_list=[non_int_list i]; 
        column_list = [column_list i]; 
    end 
end 

%run through the matrix to only in the row trans1(using the first minimum) 
row_list = trans1; 
for j=1:c
    ratio = log_mat (trans1, j); 
    if ratio <= cut_off
        non_int_list=[non_int_list j];
        row_list = [row_list j]; 
    end 
end 

%use the new transitions found in this list to look one more time 
%column list (first minimum) 
column_new = length (column_list); 
for k=2:column_new
    t2=column_list(k); %run through each of the new "good" transitions
    for i=1:r
        ratio = log_mat (i, t2); 
        if ratio <= cut_off
            non_int_list=[non_int_list i]; 
            column_list = [column_list i]; 
        end 
    end 
end 

%use the new transitions found in this list to look one more time 
%column list (first minimum) 
row_new = length (row_list); 
for k=2:row_new
    t2=row_list(k); %run through each of the new "good" transitions
    for i=1:r
        ratio = log_mat (i, t2); 
        if ratio <= cut_off
            non_int_list=[non_int_list i]; 
            row_list = [row_list i]; 
        end 
    end 
end


non_int_list = unique(non_int_list); 
non_int_list=sort(non_int_list); 
remove_list=[];
%check the final list by making a new matrix made up of ratios of these
%make sure that most of the ratios are less than cutoff, otherwise remove

%extract only the right rows 
log_mat_test=log_mat(non_int_list,:); 
log_mat_test=log_mat_test(:,non_int_list);
[r,c]=size(log_mat_test); 
for i=1:r
    flag=find(log_mat_test(i,:)>=cut_off); %will be at least 1 because of diagonal
    if numel(flag)>(r*3/4)
        remove_list=[remove_list non_int_list(i)]; 
    end 
end 
 
for i=1:length(remove_list)
    non_int_list=non_int_list(non_int_list~=remove_list(1,i));
end 

tran_names_final=cell(length(non_int_list),1); 
for j=1:length(non_int_list)
    indx=non_int_list(j); 
    tran_names_final(j) = tran_names(indx); 
end 

L=length(tran_names); 
list=[1:L]; 
int_list = []; 
for j=1:L; 
    Y=ismember(non_int_list,list(j)); 
    if sum(Y)==0 %if its not found in the array
        int_list = [int_list j]; 
    end 
end 
tran_names_int=cell(length(int_list),1); 
for j=1:length(int_list)
    indx=int_list(j); 
    tran_names_int(j) = tran_names(indx); 
end 
        

tran_names_non_int = tran_names_final'; 


end

