/*
	An Autosplitter for The Hobbit PC (2003) on patch 1.3
	ASL originally made by MD_PI, revamped by Shockster_ as an all-in-one autosplitter!
*/

state("meridian")
{
	bool onCutscene : 0x35CCE4;
	int cutsceneID : 0x35CD00; 
	bool loadScreen : 0x35F8C8;
	int oolState : 0x362B58;
	int levelID : 0x362B5C;
	bool menuClosed : 0x413040;
}

startup
{
	//Autosplitter settings.
	settings.Add("race", false, "Race Mode");
	settings.Add("ilseg", false, "ILs or Segment Practice");
	settings.Add("desc", false, "                *** Choose Starting Level Only ***", "ilseg");
	settings.Add("desc2", false, "    *** If multiple checked, priority is first level in order ***", "ilseg");
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

	//Timer state automatically detects the number of splits and determines what the runner is trying to do.
	//0 - Full Runs
	//1 - Segments or ILs
	vars.timerState = 0;
	refreshRate = 30;
	vars.levelSplitID = -1;
	vars.levelStartID = -1;

	vars.crashed = false;
	vars.ilsegmentNotCheckedMB = false;
	vars.noStartLevelMB = false;
	vars.reset = true;
	vars.started = false;
	vars.mainMenuReached = false;

	vars.resetAction = (Action)(() => 
	{ 
		vars.levelSplitID = vars.levelStartID; 
		vars.reset = true; 
		vars.started = false;
	});

	vars.splitAction = (Action)(() => 
	{
		if(vars.timerState == 0 && settings["race"]) vars.levelSplitID = 1;
		else vars.levelSplitID = vars.levelStartID;
		vars.noStartLevelMB = false; 
		vars.reset = false; 
		vars.started = true; 
	});

	vars.resetEventHandler = (LiveSplit.Model.Input.EventHandlerT<TimerPhase>)((s, e) => vars.resetAction());
	vars.splitEventHandler = (EventHandler)((s, e) => vars.splitAction());

	timer.OnReset += vars.resetEventHandler;
	timer.OnStart += vars.splitEventHandler;
}

init
{
	if(vars.crashed) System.Threading.Tasks.Task.Factory.StartNew(() => { 
			while(vars.crashed)
			{
				if(current.levelID > 0) vars.crashed = false;
			}
		});

	if(settings["ilseg"]) return true;
		
	if(!vars.ilsegmentNotCheckedMB)
	{
		vars.ilsegmentNotCheckedMB = true;
		MessageBox.Show("Enable ILs or Segment Practice option in settings to use this feature!", "Prompt", MessageBoxButtons.OK, MessageBoxIcon.Information, MessageBoxDefaultButton.Button1, MessageBoxOptions.DefaultDesktopOnly);
		return false;
	}
}

update
{
	if(current.oolState == 6 && !vars.mainMenuReached) vars.mainMenuReached = true;
	if (timer.Run.Count >= 12) vars.timerState = 0;
	else vars.timerState = 1;
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
	if(vars.started) return false;
	if(vars.timerState == 0)
	{
		if (current.levelID == -1 && current.menuClosed == true && current.oolState == 17) 	return true;
	}
	else
	{
		if(settings["ilseg"])
		{
			if(timer.CurrentPhase == TimerPhase.NotRunning && vars.mainMenuReached)
			{
				if(current.levelID == vars.levelStartID)
				{
					if(vars.levelStartID == 0 && current.oolState != 19) return true;
					if(vars.levelStartID == current.levelID && current.oolState == 19)	return true;
				}
				if(vars.levelStartID == -1)
				{
					if(!vars.noStartLevelMB)
					{
						System.Threading.Thread.Sleep(1000);
						vars.noStartLevelMB = true;
						MessageBox.Show("Please select starting level for IL or Segment timing!", "Prompt", MessageBoxButtons.OK, MessageBoxIcon.Error, MessageBoxDefaultButton.Button1, MessageBoxOptions.DefaultDesktopOnly);
					}
					return false;	
				}
			}
		}
	}
}

split
{
}

reset
{
	if(vars.crashed) return false;
	if(vars.reset) return false;
	if(vars.timerState == 1)
	{
		if(current.levelID == vars.levelStartID)
		{
			if(vars.levelStartID == 0 && current.oolState == 20 && timer.CurrentTime.GameTime.Value.TotalSeconds >= 0.05d) return true;
			if(vars.levelStartID == 1 && current.oolState == 17) return true;
			if(current.oolState == 12) return true;
		}

		if(current.levelID > vars.levelStartID + timer.Run.Count) return true;
	}

	if (current.levelID == -1) return true;
}

isLoading
{
	return current.loadScreen;
}

exit
{
	//All quests AWW crash
	if(vars.levelSplitID == 8 && timer.CurrentPhase == TimerPhase.Running) vars.crashed = true;
	vars.ilsegmentNotCheckedMB = false;
	vars.noStartLevelMB = false;
	vars.mainMenuReached = false;
	timer.OnReset -= vars.resetEventHandler;
	timer.OnSplit -= vars.splitEventHandler;
}

shutdown
{
	timer.OnReset -= vars.resetEventHandler;
	timer.OnSplit -= vars.splitEventHandler;
}
	