function y = solveTriDiag( a, b, c, f, v, w_inv )
%  Solve the  n x n  tridiagonal system for y:
%  This is an implementation of the Thomas algorithm for inverting tridiagonal
%  matrices, but highly modified to pre-compute whatever possible and not use
%  dision when used for digital ladder filters
%
%  [ a(1)  c(1)                                  ] [  y(1)  ]   [  f(1)  ]
%  [ b(2)  a(2)  c(2)                            ] [  y(2)  ]   [  f(2)  ]
%  [       b(3)  a(3)  c(3)                      ] [        ]   [        ]
%  [            ...   ...   ...                  ] [  ...   ] = [  ...   ]
%  [                    ...    ...    ...        ] [        ]   [        ]
%  [                        b(n-1) a(n-1) c(n-1) ] [ y(n-1) ]   [ f(n-1) ]
%  [                                 b(n)  a(n)  ] [  y(n)  ]   [  f(n)  ]
%
%  f must be a vector (row or column) of length n
%  a, b, c must be vectors of length n (note that b(1) and c(n) are not used)
% some additional information is at the end of the file
n = length(f);
y = zeros(n,1);
y(1) = f(1)*w_inv(1);
for i=2:n
    y(i) = ( f(i) - b(i)*y(i-1) )*w_inv(i);
end
for j=n-1:-1:1
   y(j) = y(j) - v(j)*y(j+1);
end
%  This is an implementation of the Thomas algorithm but highly modified
%  to pre-computer whatever possible and not use multiplications when used
%  for digital ladder filters; very little of the original remains
%  f, v, w_inv need to be pre-computed. This is the critical program that looks
%  after delay-free loops in a digital ladder-simulation filter
