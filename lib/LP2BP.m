function [L, C] = LP2BP(l, c, B, w0)
% [L, C] = LP2BP(l, c, B, w0) does an LP to BP on either l or c
% one of the two must be zero
if c == 0 && l > 0
    L = l/B;
    C = 1/(w0^2 * L);
elseif l == 0 && c > 0
    C = c/B;
    L = 1/(w0^2 * C);
else
    error('Either l or c must be zero and the other non-zero');
end
