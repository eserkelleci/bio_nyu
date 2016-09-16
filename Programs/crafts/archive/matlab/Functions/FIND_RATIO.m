function [ ratio_final, names_new, ratio_simple, ratio_complex] = FIND_RATIO(simple_tran, complex_tran, trans_names)
%FIND_RATIO (versions called raio_find) takes in 2 arrays with intensity values and creates 
%a matrix with all ratio permutation for each transition 
%   INPUT: 
%       -simple_tran: intensity values for simple transitions (array)
%       -complex_tran: intensity values for complex transitions (array)
%       -trans_names: cell array with transition names for both (array, no
%       header)
%   OUTPUT
%       -ratio_final: ratio of ratio_complex/ratio_simple (mat)
%       -names_new: cell array with transitions with nonzero intensities
%       (array)
%       -ratio_simple: permutation matrix for simple (mat)
%       -ratio_complex: permutation matrix for complex (mat)

%---------------------------- initialize variables -----------------------
s1=length(simple_tran); 
s2=length(complex_tran); 
simple_new=double.empty; 
complex_new=double.empty; 
names_new=cell.empty; 
z=1; %counter


%-----------get rid of NaN values, 'SUM', and zero entries----------------
for m=1:s1
    if strcmp(trans_names{m,1},'SUM')==0
        if (isnan(simple_tran(m,1))==0) && (isnan(complex_tran(m,1))==0) && (simple_tran(m,1)>0) && (complex_tran(m,1)>0)
            simple_new(z,1)=simple_tran(m,1); 
            complex_new(z,1)=complex_tran(m,1); 
            names_new{z,1}=trans_names{m,1}; 
            z=z+1;
        end 
    end 
end 

%-----------------make simple, complex matrix------------------------------
s1=length(simple_new);   
ratio_simple=zeros(s1,s1); 
ratio_complex=zeros(s1,s1); 
for m=1:s1
    a=simple_new (m,1); 
        for i=1:s1 
            ratio_simple (i,m)= simple_new(i,1)/a ;
        end 
end 

for m=1:s1
    a=complex_new (m,1); 
    for i=1:s1 
        ratio_complex (i,m)= complex_new(i,1)/a ;
    end 
end 

%---------make the ratio matrix of simple/complex-------------------------- 
ratio_final = double.empty; 
for m=1:s1
    for n=1:s1
        b=ratio_simple(m,n); 
        c=ratio_complex(m,n); 
        ratio_final(m,n)=b/c; 
    end
end 
   

end

