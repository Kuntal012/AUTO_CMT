k=load('PF04_results.txt');
g_x=[-120.25 -119.75 -120.46 -120.84 -120.25];
g_y=[35.38 35.415 36.28 36.1 35.38];
[in,on]= inpolygon(k(:,7),k(:,8),g_x,g_y);
in_fa=zeros(1,15);
cc=1;
for i=1:163
    if in(i) == 1

        in_fa(cc,:)=[k(i,:)];
        cc=cc+1;
    end
end

