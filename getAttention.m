function a=getAttention(s)

%
% "1" is assigned to "male1"
%
% "2" is assigned to "male2"
%

data = load(strcat('../EEGData/',s));
Segs = fieldnames(data);

a=zeros(length(Segs),1);

ind=1;
for s=Segs.'
    tmp = getfield(data,char(s),'attention');
    
    if tmp=='male1'
        a(ind)=1;
    elseif tmp=='male2'
        a(ind)=2;
    end
    ind = ind + 1;
end
end