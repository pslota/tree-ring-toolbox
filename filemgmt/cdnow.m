% cdnow -- change to current directory of choice

pathfull;
kmen1 = menu('Choose Current Directory',...
    'c:\work1\',...
    'c:\projs\ai3\',...
    'c:\angelika\',...
    'c:\kiyomi\',...
    'c:\victoria\',...
    'c:\angelika\saltriver\',...
    'c:\Amy\');
switch kmen1;
    case 1;
        cd c:\work1\;
    case 2;
        cd c:\projs\ai3\;
    case 3;
        cd c:\angelika\;
    case 4;
        cd c:\kiyomi\;
    case 5;
        cd c:\victoria\;
    case 6;
        cd c:\angelika\saltriver;
    case 7;
        cd c:\Amy\;
end;
