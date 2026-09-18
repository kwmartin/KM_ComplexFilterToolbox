% tst_getEvnOdd.m
% Compares polyClass's getEvn()/getOdd() (default: roots()-based, no
% Muller/setK) and getEvnMuller()/getOddMuller() (legacy: direct port of
% getEvnOddPly.m) against the existing getEvnOddPly.m free function, across
% a range of test cases, per lib/Fix_Lddr_Rlznts.md and the getEvn/getOdd
% implementation plan.
%
% For each test case: builds a polyClass object, computes the even/odd split
% three ways, and scores reconstruction accuracy (Eevn+Eodd vs the original)
% and timing. (getEvnMuller/getOddMuller are, by construction, identical to
% getEvnOddPly.m -- see git history / the original validation run -- so this
% run focuses on default vs. old/legacy accuracy and speed.)

warning('off', 'Control:ltiobject:TFComplex');
% setK.m unconditionally forces K=real(K), an assumption validated only
% against real/symmetric filter designs, not arbitrary complex polynomials
% (see cases 3/4 below). It warns rather than silently mis-selecting; that
% warning is expected to fire often here (for getEvnOddPly.m/getEvnMuller,
% which use setK) and is captured via the accuracy metrics instead, so it's
% silenced to keep this run's output readable.
warning('off', 'setK:nonNegligibleImagK');
warning('off', 'Control:ltiobject:ZPKComplex');

rng(42);

sampPts = [0.1, 1, -3, 0.5j, -2j, 1+0.5j, -1.3-2.1j, 5+5j];

results = [];

% --- Case 1: low-degree hand-checkable ---
rts = [1+2j, -0.5j, 3];
results = [results, runEvnOddCase('1-handcheck', length(rts), 1, rts, 2.0, sampPts)];

% --- Case 2: pure-imaginary roots (fast path), degree 8 and 20 ---
for N = [8 20]
    rts = 1j*sort(linspace(-3,3,N) + 0.01*randn(1,N));
    results = [results, runEvnOddCase('2-pureimag', N, 1, rts, 1.7, sampPts)];
end

% --- Case 3: real-coefficient, conjugate-paired roots ---
for N = [4 6 8 10 14 20]
    for trial = 1:5
        npairs = floor(N/2);
        a = -2 + 4*rand(1,npairs);
        b = -2 + 4*rand(1,npairs);
        rts = reshape([a+1j*b; a-1j*b], 1, []);
        if mod(N,2) == 1
            rts = [rts, -2+4*rand()];
        end
        K = 0.5 + 4.5*rand();
        results = [results, runEvnOddCase('3-realcoef', N, trial, rts, K, sampPts)];
    end
end

% --- Case 4: genuinely complex-coefficient roots (primary stress test) ---
for N = [4 6 8 10 14 20 30 40]
    for trial = 1:10
        r = 3*rand(1,N);
        theta = 2*pi*rand(1,N);
        rts = r.*exp(1j*theta);
        K = 0.5 + 4.5*rand();
        results = [results, runEvnOddCase('4-complex', N, trial, rts, K, sampPts)];
    end
end

% --- Case 5: high-degree stress ---
for N = [50 60 80]
    for trial = 1:3
        r = 3*rand(1,N);
        theta = 2*pi*rand(1,N);
        rts = r.*exp(1j*theta);
        K = 0.5 + 4.5*rand();
        results = [results, runEvnOddCase('5-highdeg', N, trial, rts, K, sampPts)];
    end
end

% --- Case 6: near-degenerate (clustered close root pairs) ---
for N = [10 20]
    for trial = 1:3
        r = 3*rand(1,N/2);
        theta = 2*pi*rand(1,N/2);
        base = r.*exp(1j*theta);
        rts = reshape([base; base + 1e-3*(randn(1,N/2)+1j*randn(1,N/2))], 1, []);
        K = 0.5 + 4.5*rand();
        results = [results, runEvnOddCase('6-neardegen', N, trial, rts, K, sampPts)];
    end
end

% --- Print summary table ---
fprintf('\n%-14s %4s %3s | %10s %10s %10s | %5s %5s | %8s %8s %8s\n', ...
    'case','N','trl','reconOld','reconMuller','reconDflt','dMull','dDflt','tOld(s)','tMull(s)','tDflt(s)');
fprintf('%s\n', repmat('-',1,100));
for i = 1:length(results)
    r = results(i);
    fprintf('%-14s %4d %3d | %10.3e %10.3e %10.3e | %5d %5d | %8.4f %8.4f %8.4f\n', ...
        r.name, r.N, r.trial, r.reconErrOld, r.reconErrMuller, r.reconErrDflt, ...
        r.degMatchMuller, r.degMatchDflt, r.timeOld, r.timeMuller, r.timeDflt);
end

% --- Per-case-family aggregate summary ---
fprintf('\n%-14s %8s %10s %10s %10s %6s %6s %8s %8s\n', ...
    'family','ntrials','maxReconOld','maxReconMull','maxReconDflt','dMullOK','dDfltOK','speedupM','speedupD');
fprintf('%s\n', repmat('-',1,95));
names = unique({results.name}, 'stable');
for i = 1:length(names)
    idx = strcmp({results.name}, names{i});
    sub = results(idx);
    fprintf('%-14s %8d %10.3e %10.3e %10.3e %6d %6d %8.2f %8.2f\n', ...
        names{i}, sum(idx), max([sub.reconErrOld]), max([sub.reconErrMuller]), max([sub.reconErrDflt]), ...
        all([sub.degMatchMuller]), all([sub.degMatchDflt]), ...
        sum([sub.timeOld])/sum([sub.timeMuller]), sum([sub.timeOld])/sum([sub.timeDflt]));
end

function res = runEvnOddCase(name, N, trial, rts, K, sampPts)
    Epl = polyClass(rts, K);

    tic;
    [Eevn_old, Eodd_old] = getEvnOddPly(Epl);
    timeOld = toc;

    tic;
    Eevn_muller = Epl.getEvnMuller();
    Eodd_muller = Epl.getOddMuller();
    timeMuller = toc;

    tic;
    Eevn_dflt = Epl.getEvn();
    Eodd_dflt = Epl.getOdd();
    timeDflt = toc;

    scale = max(1, max(abs(rts)));
    s = sampPts * scale;

    reconErrOld = maxRelErr(Eevn_old.peval(s)+Eodd_old.peval(s), Epl.peval(s));
    reconErrMuller = maxRelErr(Eevn_muller.peval(s)+Eodd_muller.peval(s), Epl.peval(s));
    reconErrDflt = maxRelErr(Eevn_dflt.peval(s)+Eodd_dflt.peval(s), Epl.peval(s));

    res = struct('name',{name},'N',{N},'trial',{trial}, ...
        'reconErrOld',{reconErrOld},'reconErrMuller',{reconErrMuller},'reconErrDflt',{reconErrDflt}, ...
        'degMatchMuller',{Eevn_muller.N==Eevn_old.N && Eodd_muller.N==Eodd_old.N}, ...
        'degMatchDflt',{Eevn_dflt.N==Eevn_old.N && Eodd_dflt.N==Eodd_old.N}, ...
        'timeOld',{timeOld},'timeMuller',{timeMuller},'timeDflt',{timeDflt});
end

function e = maxRelErr(a, b)
    a = a(:); b = b(:);
    denom = max(1, abs(b));
    e = max(abs(a-b)./denom);
end
