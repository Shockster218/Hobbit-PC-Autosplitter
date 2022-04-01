/*
	An Autosplitter for The Hobbit PC (2003) on patch 1.3
	ASL originally made by MD_PI, revamped by Shockster_ as an all-in-one autosplitter!
*/

state("meridian")
{
	// Not sure what runLevel is exactly, but needed for kill bilbo (need to ask md_pi)
	bool runLevel : 0x360354;
	bool onCinema : 0x35CCE4;
	int cinemaID : 0x35CD00;
	float health : 0x35BDBC;
	bool onCutscene : 0x35CCE4;
	int cutsceneID : 0x35CD00; 
	bool loadScreen : 0x35F8C8;
	int levelQueued : 0x3631EC;
	int oolState : 0x362B58;
	int levelID : 0x362B5C;
	int menusOpen : 0x413038, 0x5C8;
}

startup
{
/*
	Autosplitter Settings.
	The settings hierarchy is as follows in order as they appear.
	1. Full Game Runs
		1. NMG
		2. All Quests / 100%
		3. Glitchess / Category Extensions
*/
	settings.Add("runsHeader", false, "               -------- Run Settings --------");
	settings.Add("fullgame", true, " Full Game Runs");
	settings.SetToolTip("fullgame", "If checked, takes precedence over Any% and ILs/Segment Runs.");
	settings.Add("nmg", true, " No Major Glitches", "fullgame");
	settings.Add("aq100", false, " All Quests or 100%", "fullgame");
	settings.Add("other", false, " Other Full Game Run", "fullgame");
	settings.SetToolTip("other", " Glitchless, No Jump-Attacks, No Longjumps, etc.");
	settings.Add("race", false, " Race Mode", "nmg");

/*
	2. Any Percent Runs
		1. Major Glitches
		2. Kill Bilbo
		3. Crash% - Any Type
*/
	settings.Add("any%", false, " Any Percent Runs");
	settings.SetToolTip("any%", "If checked, takes precedence over IL/Segment Runs but not Full Game Runs.");
	settings.Add("mg", false, " Major Glitches", "any%");
	settings.SetToolTip("mg", " Please include splits for Dream World, OHaUH, AWW and Final split to work correctly!");
	settings.Add("killbilbo", false, " Kill Bilbo", "any%");
	settings.Add("crash%", false, " Crash%", "any%");
/*
	3. IL or Segmented Practice
*/
	settings.Add("ilseg", false, "ILs or Segment Practice");
	settings.SetToolTip("ilseg", "Lowest priority out of the main categories.\nChoose Starting Level Only! If multiple checked, priority is first level as appears in order below.");
	settings.Add("dw", false, " Dream World", "ilseg");
	settings.Add("aup", false, " An Unexpected Party", "ilseg");
	settings.Add("rm", false, " Roast Mutton", "ilseg");
	settings.Add("th", false, " Troll-Hole", "ilseg");
	settings.Add("oh", false, " Over Hill and Under Hill", "ilseg");
	settings.Add("ritd", false, " Riddles in the Dark", "ilseg");
	settings.Add("fas", false, " Flies and Spiders", "ilseg");
	settings.Add("boob", false, " Barrels out of Bond", "ilseg");
	settings.Add("aww", false, " A Warm Welcome", "ilseg");
	settings.Add("ii", false, " Inside Information", "ilseg");
	settings.Add("gotc", false, " Gathering of the Clouds", "ilseg");
	settings.Add("tcb", false, " The Clouds Burst", "ilseg");

	settings.Add("extraHeader", false, "               -------- Extra Settings --------");
	settings.Add("signs", true, " Automatically Reset Riddles in the Dark Minecart Signs");
	settings.Add("resets", true, " Automatically Disable Resets When the Game Crashes");
/*
	Timer state for conditions based on what the preferred category is.
	0 - Full Game Runs
	1 - Segments or ILs
	2 - Any Percent Runs
*/
	vars.timerState = 0;
	refreshRate = 30;
	vars.levelSplitID = -1;
	vars.levelStartID = -1;

	vars.crashed = false;
	vars.noStartLevelMB = false;
	vars.mainMenuReached = false;
}

init
{
	// All common reset actions are done here to avoid redundancy
	vars.resetAction = (Action)(() => 
	{
		if (vars.levelSplitID > 4 && settings["signs"])
		{
			// Set Switches back to normal. for 1.3 only
			memory.WriteBytes((System.IntPtr)(0x75B548), new byte[] {0x01,0,0,0,0,0,0,0,0,0,0,0,0x01,0,0,0,0,0,0,0});
		}	
		vars.levelSplitID = vars.levelStartID; 
	});

	// All common start actions are done here to avoid redundancy
	vars.startAction = (Action)(() => 
	{	
		if(vars.timerState == 0)
		{
			if(settings["race"]) vars.levelSplitID = 1;
			else vars.levelSplitID = 0;
		} 
		else vars.levelSplitID = vars.levelStartID;
		vars.noStartLevelMB = false; 
	});

	// Create eventhandlers to bind
	vars.resetEventHandler = (LiveSplit.Model.Input.EventHandlerT<TimerPhase>)((s, e) => vars.resetAction());
	vars.startEventHandler = (EventHandler)((s, e) => vars.startAction());

	// Bind event handlers
	timer.OnReset += vars.resetEventHandler;
	timer.OnStart += vars.startEventHandler;

/*
	Set AWW crash to true to disable resetting function when back in game
	Very Useful for categories like AQ where save jump is present.
*/
	if(vars.crashed) System.Threading.Tasks.Task.Factory.StartNew(() => { 
		while(vars.crashed)
		{
			if(vars.mainMenuReached && current.levelID > -1) vars.crashed = false;
		}
	});
}

update
{
	if(current.oolState == 6 && !vars.mainMenuReached) vars.mainMenuReached = true;

	// Default to full game runs if nothing checked.
	if(settings["fullgame"]) vars.timerState = 0;
	else if(settings["ilseg"]) vars.timerState = 1;
	else if(settings["any%"]) vars.timerState = 2;
	else vars.timerState = 0;

	if(vars.timerState == 1)
	{	
		if(settings["tcb"]) vars.levelStartID = 11;
		else if(settings["gotc"]) vars.levelStartID = 10;
		else if(settings["ii"]) vars.levelStartID = 9;
		else if(settings["aww"]) vars.levelStartID = 8;
		else if(settings["boob"]) vars.levelStartID = 7;
		else if(settings["fas"]) vars.levelStartID = 6;
		else if(settings["ritd"]) vars.levelStartID = 5;
		else if(settings["oh"]) vars.levelStartID = 4;
		else if(settings["th"]) vars.levelStartID = 3;
		else if(settings["rm"]) vars.levelStartID = 2;
		else if(settings["aup"]) vars.levelStartID = 1;
		else if(settings["dw"]) vars.levelStartID = 0;
		else vars.levelStartID = -1;
	}
	else vars.levelStartID = -1;
}

start
{
	// If timer is running or not at main menu, we don't need to check for start conditions.
	if(timer.CurrentPhase != TimerPhase.NotRunning || !vars.mainMenuReached) return false;

	// IL and Segment runs start conditions.
	if(vars.timerState == 1)
	{
		// If we have a start level selected, get ready to start.
		if(current.levelID == vars.levelStartID)
		{
			// Start condition for dreamworld ILs or segments starting from there.
			if(vars.levelStartID == 0 && current.oolState != 19) return true;

			// Start condition for other levels.
			if(current.oolState == 19)	return true;
		}
		// If we don't have a start level selected, don't start.
		else if(vars.levelStartID == -1 && !vars.noStartLevelMB)
		{
			System.Threading.Thread.Sleep(1000);
			vars.noStartLevelMB = true;
			MessageBox.Show("Please select starting level for IL or Segment timing!", "Prompt", MessageBoxButtons.OK, MessageBoxIcon.Error, MessageBoxDefaultButton.Button1, MessageBoxOptions.DefaultDesktopOnly);
			return false;
		}
	}
	else
	{
		// Default start conditions for non practice.
		if (current.oolState == 17 && (old.oolState == 9 || old.oolState == 6) && current.menusOpen < 2) 
		{
			// If running menu glitches and not enough splits are present, give warning.
			if(settings["mg"] && timer.Run.Count != 4) MessageBox.Show("Please include splits for Dream World, OHaUH, AWW and Final split to work correctly!", "Prompt", MessageBoxButtons.OK, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button1, MessageBoxOptions.DefaultDesktopOnly);
			return true;
		}
	}
}

split
{
	// If timer isn't running, we don't need to check split conditions.
	if(timer.CurrentPhase != TimerPhase.Running) return false;

	// Final split condition, except for any% runs since they don't end on the conventional barrel hit.
	if(vars.timerState != 2)
	{
		// Split for TCB on full game runs or segments (that end on TCB) and TCB IL
    	if (current.levelID > 10 && current.onCinema && current.cinemaID == 0x3853B400)
    	{
			if(vars.timerState == 0) vars.levelSplitID = -1; 
			else vars.levelSplitID = vars.levelStartID;
    	    return true;
		}
	}
	else
	{
		// Only need different final split condition for kill bilbo.
		// Split if health is 0 during gameplay
		if(settings["killbilbo"] && current.health == 0 && current.runLevel && !current.loadScreen) return true;
	}

	// Split conditions for menu glitches, since its the only category that skips around.
	// We put all conditions out here and even the final condition because of how unique it is.
	if(settings["mg"] && timer.CurrentSplitIndex > 0) 
	{
		if (current.levelID == 4) return true;
		else if(current.levelID == 8) return true;
		// Split if playing the storybook cinema for The Clouds Burst, which is necessary for major glitches.
		else if(current.levelID > 11 && current.oolState == 17) return true;
	}
	else
	{
		// Normal split condition for everything else thats a full game run and ILs/Segments
		if (current.oolState == 19 && current.levelID > vars.levelSplitID)
    	{
    		vars.levelSplitID += 1;
    		return true;
    	}
	}
}

reset
{
	// Don't reset if we crashed
	if(vars.crashed) return false;

	// Otherwise if we didn't crash during that, reset the timer on game start. Still resets for crash%(since no split happens anyway), might change.
	if(!vars.mainMenuReached && timer.CurrentPhase == TimerPhase.Running) return true;

	// If the timer isn't started, then we don't need to check for reset conditions.
	if(timer.CurrentPhase != TimerPhase.Running) return false;

	// If doing menu glitches and we have menus open, dont reset when we go back to the main menu.
	if(settings["mg"] && current.menusOpen > 1) return false;

	// If we load a save and it's not for the current level we are on, reset.
	if(current.levelQueued != -1 && current.levelQueued != vars.levelSplitID) return true;

	// IL and segment reset conditions
	if(vars.timerState == 1)
	{
		if(current.levelID == vars.levelStartID)
		{
			// Reset condition for dream world.
			if(vars.levelStartID == 0 && current.oolState == 20 && timer.CurrentTime.GameTime.Value.TotalSeconds >= 0.05d) return true;

			// Reset condition for AUP.
			if(vars.levelStartID == 1 && current.oolState == 17) return true;

			// Reset condition for all other level segments.
			if(current.oolState == 12) return true;
		}

		// If for some reason we load a save thats passed the levels or before the start level in the segment or IL, we reset.
		if(current.levelID > vars.levelStartID + timer.Run.Count || current.levelID < vars.levelStartID) return true;
	}

	// Generic reset check; if we get to main menu. Already check for menu glitches.
	if (current.levelID == -1 && current.oolState == 6) return true;
}

isLoading
{
	return current.loadScreen;
}

exit
{
	// All quests AWW crash check.
	if(settings["resets"]) vars.crashed = true;

	// Crash% display time as checkbox since split action doesn't run after the game has crashed. Most likely inaccurate, but better than nothing I guess?
	if(vars.timerState == 2 && settings["crash%"] && timer.CurrentPhase == TimerPhase.Running) MessageBox.Show("Crash% Time Recorded at " + ((TimeSpan)timer.CurrentTime.GameTime).ToString(@"mm\:ss\.fff") + "\nMay not be accurate due to limitations.", "Prompt", MessageBoxButtons.OK, MessageBoxIcon.Information, MessageBoxDefaultButton.Button1, MessageBoxOptions.DefaultDesktopOnly);
	
	// Reset bools for when we lose process handle.
	vars.noStartLevelMB = false;
	vars.mainMenuReached = false;

	//Remove event handlers. Since we add on init, just remove here to avoid problems.
	timer.OnReset -= vars.resetEventHandler;
	timer.OnStart -= vars.startEventHandler;
}

shutdown
{
	//Remove event handlers to avoid any problems.
	timer.OnReset -= vars.resetEventHandler;
	timer.OnStart -= vars.startEventHandler;
}
	