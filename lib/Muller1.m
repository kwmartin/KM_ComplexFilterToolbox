% Author         : Chandan Kumar
% Title          : Finding roots of Polynomial Equation by Muller's method
% Date           : 3rd Dec 2009
% Last Modified  : 3rd Dec 2009
% Muller's method uses three points, 
% constructs the parabola through these three points, 
% and takes the intersection of the x-axis with the parabola
% to be the next approximation.
% The order of convergence of Muller's method is approximately 1.84.
% This method could be advantageous if looking for a complex roots, 
% since any iterates can be complex even if previous ones are real.
%
% Procedure to run the code:
% Press F5 or RUN, then in command window a message would be displayed-
% "Polynomial function of Order "n" is of type:a[1]X^n+a[2]X^(n-1)+ ..+a[n]X^1+a[n+1]
% Type Coeff as "[ 1 2 3 ...]" i.e Row vector form."
% Enter the values according to above order.
% If polynomial is more than 1st order, it would ask for three initial guess for 
% iteration. 
% Please provide with three distinct numbers or else error message would be displayed.

% e.g. 
% Enter the coefficient in order? [1 2 3 4 5]
% Give the three initial guess point [x0, x1, x2]: [-1 0 1] 
% or any other three distinct number,
% If the range of solution is known then using a value close to that range
% might yeild a faster result. Or if you dont  have any clue about value of root
% then just press enter when ask for guess, and it would use default value
% of [1 2 3].


function Muller1()
clc, clear all                                      % Clears the command window and variables
syms x                                              % variable x declared symbol
R_Accuracy = 1e-8;                                  % No of digit for termination
A_x = 0;                                            % Function initiallization
flag =1;                                            % Flag will be used for terminating process
Root_index =0;
disp('Polynomial function of Order "n" is of type:a[1]X^n+a[2]X^(n-1)+ ..+a[n]X^1+a[n+1]');
disp('Type Coeff as "[ 1 2 3 ...]" i.e Row vector form');
Coeff = input('Enter the coefficient in order? ');
[row_initial,col_initial] = size(Coeff);
for i = 1:col_initial
    A_x = A_x + Coeff(i)*(x^(col_initial-i));       % Polynomial function building
end
clc
disp('Polynomial is : ');
disp(A_x)
        
while(flag)
    [row,col] = size(Coeff);
    if (col ==1)
        flag =0;
    elseif(col==2)
        flag =0;
        Root_index = Root_index + 1;
        Root(Root_index)= -Coeff(2)/Coeff(1);
        disp(['Root found:' num2str(-Coeff(2)/Coeff(1)) '']);
        disp(' ')
    elseif(col >= 3)
        Guess = input('Give the three initial guess point [x0, x1, x2]: ');
        if isempty(Guess)
            Guess = [1 2 3];
            disp('Using default value [1 2 3]')
        elseif(Guess == zeros(1,3))
            break
        end
        disp(['Three initial guess are: ' num2str(Guess) ' ']);
        for i = 1:100
            h1 = Guess(2)-Guess(1);
            h2 = Guess(3)-Guess(2);
            d1 = (polyval(Coeff,Guess(2))-polyval(Coeff,Guess(1)))/h1;
            d2 = (polyval(Coeff,Guess(3))-polyval(Coeff,Guess(2)))/h2;
            d = (d2-d1)/(h1+h2);
            b = d2 + h2*d;
            Delta = sqrt(b^2-4*polyval(Coeff,Guess(3))*d);
            if (abs(b-Delta)<abs(b+d))
                E = b + Delta;
            else
                E = b - Delta;
            end
            h = -2*polyval(Coeff,Guess(3))/E;
            p = Guess(3) + h;
            if (abs(h) < R_Accuracy)
                Factor = [1 -p];
                Root_index = Root_index + 1;
                Root(Root_index)= p;
                disp(['Root found: ' num2str(p) ' ']);
%                 disp(['Root found after' num2str(i) ' no of iteration.']);
                disp(' ')
                break;
            else
                Guess = [Guess(2) Guess(3) p]; 
            end
            if (i ==99)
                disp('Method failed to find root!!!');
            end
        end
    end
    [Coeff,rem] = deconv(Coeff,Factor);
    Coeff;
end
disp(['Function has ' num2str(Root_index) ' roots, given as:']);
for i = 1:Root_index
    disp(['Root no ' num2str(i) '  is ' num2str(Root(i)) ' .'])
end
disp('End of Program');
        










% 
% 
%  Mller's method uses three points,  It constructs a parabola through these three points,  and takes the intersection of the x-axis with the parabola to be the next approximation. The order of convergence of Mller's method is approximately 1.84. This method could be advantageous if looking for a complex roots,  since any iterates can be complex even if previous ones are real.
% 
% Procedure to run the code:
%  Press F5 or RUN, then in command window a message would be displayed- "Polynomial function of Order "n" is of type:a[1]X^n+a[2]X^(n-1)+ ..+a[n]X^1+a[n+1]
%  Type Coeff as "[ 1 2 3 ...]" i.e Row vector form."
% Enter the values according to above order.
% If polynomial is more than 1st order, it would ask for three initial guess for  iteration. 
%  Please provide with three distinct numbers or else error message would be displayed.
% 
%  e.g. 
% Enter the coefficient in order? [1 2 3 4 5]
%  Give the three initial guess point [x0, x1, x2]: [-1 0 1] 
%  or any other three distinct number,
%  If the range of solution is known then using a value close to that range might yeild a faster result. Or if you dont  have any clue about value of root then just press enter when ask for guess, and it would use default value of [1 2 3]. If you have found the desired root that you want you can terminate the process any time, writing 

