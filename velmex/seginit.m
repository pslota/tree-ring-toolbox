function initdlg = seginit()
	initdlgtext = {'Initialize segment as follows:','  * Position the stage','  * press RESET -- sets Quick-Check display to zero','  * press PRINT -- marks starting point for measuring'};
	initdlg = msgbox(initdlgtext,'Message');
end