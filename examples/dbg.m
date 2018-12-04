  warning('off', 'Control:combination:connect9');

  N = 2;
  for i = 1:1
    Nm = {[1], [1]};
    Dn = {[1, 2], [1, 2]};
    T_f = tf(Nm, Dn);
    T_f.y = sprintf('x%d',i);
    T_f.u{1} = sprintf('x%d',i-1);
    T_f.u{2} = sprintf('x%d',i+1);
    TF{i} = T_f;
  end
  TF{2} = tf({[1], [0]}, {[1, 1], [1]});
  TF{2}.u = {'x1', 'Null'};
  TF{2}.y = {'x2'};
  Tf = connect(TF{:}, 'x0', 'x2');
  Fltr = simpl(zpk(Tf(1)));

  for i = 1:N
    uCells{i} = sprintf('u%d', i);
    xinCells{i} = sprintf('xin%d', i);
    eCells{i} = sprintf('e%d', i);
    xCells{i} = sprintf('x%d', i);
    KfoCells{i} = sprintf('Kfo%d', i);
  end

  KiMtrx = zeros(N);
  KiMtrx(1,1) = 1;
  
  KI = tf(KiMtrx);
  KI.u = xinCells;
  KI.y = uCells;

  Sm = sumblk('%e = %u + %Kfo', eCells, uCells, KfoCells);

  KfMtrx = [-2, 1; 1, -1];
  KF = tf(KfMtrx);
  KF.u = xCells;
  KF.y = KfoCells;

  TF2 = {};
  for i = 1:N
    for j = 1:N
      if j == i
        Nm{j} = [1];
        Dn{j} = [1, 0];
      else
        Nm{j} = [0];
        Dn{j} = [1];
      end
    end
    Tf1 = tf(Nm, Dn);
    TF2{i} = Tf1;
    TF2{i}.u = eCells;
    TF2{i}.y = xCells{i};
  end

  TF2{end + 1} = Sm;
  TF2{end + 1} = KI;
  TF2{end + 1} = KF;
  TF3 = connect(TF2{:}, 'xin1', 'x2');
  Fltr2 = simpl(zpk(TF3(1)));

  a=1;