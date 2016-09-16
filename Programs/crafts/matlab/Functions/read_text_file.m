% read text file;

function text = read_text_file(fid)

k=0;
while ~feof(fid)
    cur = fgetl(fid);
    if ~isempty(cur)
        k = k+1;
        text{k} = cur;
    end;
end;
