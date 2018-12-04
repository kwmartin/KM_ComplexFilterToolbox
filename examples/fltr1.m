% A simple ladder filter from example 9 of Snelgrove, Sedra, Lang Brackett, "Complex Analog Filters"

wp = [-1, 1];
ws = [-2, 2];
E = zpk([-1], [], 1.41421);
P = zpk([1j], [], 1);
H= P/E;

lddr = ladderClass();
elem1 = ladderElem(0, 0, 2.41421*j, 0, 'SRX');
elem2 = ladderElem(1.70711, 0, -1.70711*j, 0, 'SHL');
elem3 = ladderElem(0, 0, -2.41421*j, 0, 'SRX');
lddr.addElem(elem1);
lddr.addElem(elem2);
lddr.addElem(elem3);
lddr.R1 = 1;
lddr.R2 = 5.82843;
lim = [-10, 10, -30, 10,];
[fdb, fref_db] = plot_lddr(H, lddr, wp, ws, 'b', lim);

a=1;
