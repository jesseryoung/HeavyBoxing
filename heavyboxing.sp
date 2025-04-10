/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#define REQUIRE_EXTENSIONS
#include <tf2_stocks>
#include <tf2>
#include <sdktools_functions>
#include <sdktools>
#include <adminmenu>


new String:UpdateDate[] = "8/10/10";
new TFClassType:SDclass = TFClass_Heavy;
new bool:SudddenDeathTime = false;
new bool:BoxingTime = false;

	/* Keep track of the top menu */
new Handle:hAdminMenu = INVALID_HANDLE

public Plugin:myinfo = 
{
	name = "Heavy Boxing Sudden Death Mod",
	author = "Jesse Young (CodeMonkey)",
	description = "At sudden death changes all classes to Heavy and removes all wepons except gloves",
	version = "1.0",
	url = "http://www.team-brh.com"
}

public OnPluginStart()
{
	// Add your own code here...
	RegConsoleCmd("SD_update",Update);
	RegAdminCmd("sd_startboxing",StartBoxing2,ADMFLAG_ROOT);
	//RegConsoleCmd("startplay",startplay);
	RegConsoleCmd("stopplay",stopplay);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("teamplay_round_stalemate", Event_SuddenDeathStart);
	HookEvent("teamplay_round_start", Event_SuddenDeathEnd);
	HookEvent("teamplay_round_win", Event_SuddenDeathEnd);
	
	
	
	
	
	
	//Admin menu stuff

	/* See if the menu pluginis already ready */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		/* If so, manually fire the callback */
		OnAdminMenuReady(topmenu);
	}

	
}


public OnConfigsExecuted() {
	PrecacheSound("suddendeath/hbm.mp3",true);
	AddFileToDownloadsTable("sound/suddendeath/hbm.mp3");
}

public Action:startplay(client, args) {
	StartSong();
	return Plugin_Handled;
	
}
public Action:stopplay(client,args) {
	StopSound(client,SNDCHAN_STATIC,"suddendeath/hbm.mp3");
	return Plugin_Handled;
	
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hAdminMenu = INVALID_HANDLE;
	}
}


public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hAdminMenu)
	{
		return;
	}
	hAdminMenu = topmenu;
 
	/* :TODO: Add everything to the menu! */
		/* If the category is third party, it will have its own unique name. */
	new TopMenuObject:server_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS);
 
	AddToTopMenu(hAdminMenu, "sd_startboxing", TopMenuObject_Item, StartBoxing, server_commands, "sd_startboxing", ADMFLAG_ROOT);
}

public StartBoxing(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Start/Stop Heavy Boxing");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		/* Do something! client who selected item is in param */
		StartBoxing2(param,0);
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if (SudddenDeathTime || BoxingTime) {
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		TF2_SetPlayerClass(client,SDclass,false,false);
		TF2_RegeneratePlayer(client);
		
		
		
		GiveGloves(client)
	}
	
	

	
	return Plugin_Continue;
	
}

public Event_SuddenDeathStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	SudddenDeathTime = true;
	
	
	for (new i = 1; i <= GetMaxClients(); i++){
		if (!IsClientConnected(i) || !IsClientInGame(i) || IsClientObserver(i))
			continue;
		
		TF2_RespawnPlayer(i);
	}
	
	//Disable Point Capping
	ToggleObjectiveState(false);
	
	StartSong();
	
	PrintToChatAll("\x04[SD]Sudden death heavy boxing started. No capping during sudden death. Type 'stopplay' in console to stop music");
}

public Event_SuddenDeathEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	if (SudddenDeathTime) {
		SudddenDeathTime = false;
		StopSong();
		//Enable Point Capping
		ToggleObjectiveState(true);
	}
	

	
}


public GiveGloves(client) {



	new index = -1;
	new item = 0;
	while ((index = GetPlayerWeaponSlot(client, item)) != -1)
	{
		RemovePlayerItem(client, index);
		RemoveEdict(index);
		item++;
		if (item == 2)
			item++;
	}
	new entity = GetPlayerWeaponSlot(client,2);
	if (IsValidEntity(entity))
		EquipPlayerWeapon(client, entity);
	
}

public Action:Update(client,args) {
	
	ReplyToCommand(client,"Updated on %s",UpdateDate)
	return Plugin_Handled
}

public Action:StartBoxing2(client,args) {
	BoxingTime = !BoxingTime;
	new String:name[32];
	GetClientName(client,name,sizeof(name));
	PrintToChatAll("\x04[SD]Admin %s enabled/disabled Heavy Boxing mode",name);
	
	if (BoxingTime) {
		//Disable lockers`
		new iRegenerate = -1;
		while((iRegenerate = FindEntityByClassname(iRegenerate, "func_regenerate")) != -1) 
        { 
            AcceptEntityInput(iRegenerate, "Disable"); 
        }
		StartSong()
	}else {
		//Disable lockers`
		new iRegenerate = -1;
		while((iRegenerate = FindEntityByClassname(iRegenerate, "func_regenerate")) != -1) 
        { 
            AcceptEntityInput(iRegenerate, "Enable"); 
        }
		
		StopSong();
	}
	
	for (new i = 1; i <= GetMaxClients(); i++){
		if (!IsClientConnected(i) || !IsClientInGame(i) || IsClientObserver(i))
			continue;
		
		TF2_RespawnPlayer(i);
	}
	

		
	
	return Plugin_Handled;
}

public StartSong() {
	EmitSoundToAll("suddendeath/hbm.mp3",SOUND_FROM_PLAYER,SNDCHAN_STATIC);
}

public StopSong() {
	for (new i=1; i <= GetMaxClients(); i++) {
		if (!IsClientConnected(i) || !IsClientInGame(i))
			continue;
		StopSound(i,SNDCHAN_STATIC,"suddendeath/hbm.mp3");
	}	
}

// Blatenly stolen from: https://forums.alliedmods.net/showthread.php?t=140862
ToggleObjectiveState(bool:newState)
{
	/* Things to enable or disable */
	new String:targets[5][50] = {"team_control_point_master","team_control_point","trigger_capture_area","item_teamflag","func_capturezone"};
	new String:input[8] = "Disable";
	if(newState) input = "Enable";

	/* Loop through things that should be enabled/disabled, and push it as an input */
	new ent = 0;
	for (new i = 0; i < 5; i++)
	{
		ent = MaxClients+1;
		while((ent = FindEntityByClassname(ent, targets[i]))!=-1)
		{
			AcceptEntityInput(ent, input);
		}
	}
	LogMessage("[SM] Objective State Now: %sd", input);
}