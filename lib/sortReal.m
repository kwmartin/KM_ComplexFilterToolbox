function pls = sortReal(p, tol)
%SORTREAL Sort poles by real part, then imaginary part for nearly equal
%real parts.
%
%   pls = sortReal(p)
%   pls = sortReal(p, tol)
%
%   Values are sorted by ascending real part. Consecutive values whose
%   real parts differ by no more than tol form a group; values within
%   each group are sorted by ascending imaginary part.

    if nargin < 2 || isempty(tol)
        tol = 100 * eps(max(1, max(abs(real(p)))));
    end

    wasRow = isrow(p);
    p = p(:);

    p = sort(p, 'ComparisonMethod', 'real');

    re = real(p);
    group = cumsum([true; abs(diff(re)) > tol]);

    pls = zeros(size(p), 'like', p);

    for k = 1:group(end)
        idx = (group == k);
        pk = p(idx);
        if length(pk) == 2
            p_k = [0.5*real(pk(1) + pk(2)) + j*0.5*imag(pk(1) - pk(2)) ; ...
                0.5*real(pk(1) + pk(2)) - j*0.5*imag(pk(1) - pk(2))];
            pk = p_k;
            pls(idx) = pk;
        else
            [~, order] = sort(imag(pk), 'ascend');
            pls(idx) = pk(order);
        end
    end

    if wasRow
        pls = pls.';
    end
end
