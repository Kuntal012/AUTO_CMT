%modified from:
%http://www.cs.unm.edu/~mueen/FastestSimilaritySearch.html
%to produce cros_correlation 
function cc=findCC(x,y)


    %x is the data, y is the query
    n = length(x);
    %y = (y-mean(y))./std(y,1);                      %Normalize the query. If you do not want to normalize just comment this line.
    m = length(y);
    x(n+1:2*n) = 0;                                 %Append zeros
    y = y(end:-1:1);                                %Reverse the query
    y(m+1:2*n) = 0;                                 %Append zeros

    %The main trick of getting dot products in O(n log n) time. The algorithm is described in [a].
    X = fft(x);                                     %Change to Frequency domain
    Y = fft(y);                                     %Change to Frequency domain
    Z = X.*Y;                                       %Do the dot product
    z = ifft(Z);                                    %Come back to Time domain

    
    %compute y stats -- O(n)
    sumy2 = sqrt(sum(y.^2));

    %compute x stats -- O(n)
    cum_sumx2 = cumsum(x.^2);                       %Cumulative sums of x^2
    sumx2 = sqrt(cum_sumx2(m:n)-[0;cum_sumx2(1:n-m)]);      %Sum of x^2 of every subsequences of length m

cc=z(m:n)./(sumx2*sumy2);


%the front part
cum_sumy2=cumsum(y.^2);
cc_front=z(1:m-1)./(sqrt(cum_sumy2(1:m-1)).*sqrt(cum_sumx2(1:m-1)));

%the tail part
sumx2_ap = sqrt(cum_sumx2(n+1:n+m-1)-cum_sumx2(n-m+1:n-1)); 
cum_sumy2_ap=sqrt(cumsum((y(m-1:-1:1)).^2));
cum_sumy2_ap=cum_sumy2_ap(end:-1:1);
cc_ap=z(n+1:n+m-1)./(sumx2_ap.*cum_sumy2_ap);


cc=[cc_front;cc;cc_ap];

%Nader Shakibay Senobari, summer 2016