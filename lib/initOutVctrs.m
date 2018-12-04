function [a, b, c, f, v, w_inv] = initOutVctrs(TFs)
%   [a, b, c, f] = initOutVctrs(TFs) inits vectors for solving the tridiagonal 
%   delay-free output matrix of the ladder simulation
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

N = length(TFs);
a = ones(N,1);
b = zeros(N,1);
c = zeros(N,1);
f = zeros(N,1);

for i=2:N
  b(i) = -TFs{i}.D(1);
end
for i=1:N-1
  c(i) = -TFs{i}.D(2);
end
for i=1:N
  f(i) = TFs{i}.C;
end

v = zeros(N,1);   
y = v;
w = v;
w(1) = a(1);
y(1) = f(1)/w(1);
for i=2:N
    v(i-1) = c(i-1)/w(i-1);
    w(i) = a(i) - b(i)*v(i-1);
end
w_inv = 1./w;
a_=1;
