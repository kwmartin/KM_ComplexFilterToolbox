function goDbg
    st = dbstack('-completenames');

    if isempty(st)
        error('MATLAB is not currently stopped in the debugger.');
    end

    matlab.desktop.editor.openAndGoToLine(st(1).file, st(1).line);
end