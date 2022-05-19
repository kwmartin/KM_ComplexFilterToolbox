function tmMltplys()
    for n=[64 128 256 512 1024 2048 4096]
        fprintf('For n=%d ',n);
        a = rand(n,n) + j*rand(n,n);
        b = rand(n,n) + j*rand(n,n);
        c = mlt(a,b);
    end


    function c = mlt(a, b)
    % multiply two matrices
        tic
        c = a*b;
        toc
    end
end
