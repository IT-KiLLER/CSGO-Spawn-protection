#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#pragma semicolon 1
#pragma newdecls required
float playertime[MAXPLAYERS+1] = {0.0, ...};
ConVar sm_spawn_protection_time;
	
public Plugin myinfo = 
{
	name = "[CS:GO] Spawn protection", 
	author = "IT-KiLLER", 
	description = "Players can not be damaged in a few seconds after spawn.", 
	version = "1.1", 
	url = "https://github.com/it-killer"
}

public void OnPluginStart()
{
	sm_spawn_protection_time  = CreateConVar("sm_spawn_protection_time", "15.0", "How long the player will be protected after spawn. 0 = disabled or time 1-180 seconds.", _, true, 0.0, true, 180.0);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Pre);
	sm_spawn_protection_time.AddChangeHook(OnConVarChange);
	for(int client = 1; client <= MaxClients; client++)
		if(IsClientInGame(client))
			OnClientPutInServer(client);
}

public void OnConVarChange(Handle hCvar, const char[] oldValue, const char[] newValue)
{
	if (StrEqual(oldValue, newValue)) return;
	if (hCvar == sm_spawn_protection_time)
		for(int client = 1; client <= MaxClients; client++) 
			if(IsClientInGame(client)) {
				playertime[client] = 0.0;
				if(sm_spawn_protection_time.BoolValue)
					SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
				else
					SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			}
}

public void OnClientDisconnect_Post(int client)
{
	playertime[client] = 0.0;
}
	
public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{	
	if(!sm_spawn_protection_time.BoolValue) return;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	playertime[client] = GetGameTime();
}

public void OnClientPutInServer(int client)
{
	if(!sm_spawn_protection_time.BoolValue) return;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor,float &damage, int &damagetype)
{
	if(!IsValidClient(client) || !sm_spawn_protection_time.BoolValue) return Plugin_Continue;
	if (!client || (playertime[client] + sm_spawn_protection_time.FloatValue )> GetGameTime()) {
		PrintHintText(client, "You are protected for another <font color='#00ff00'>%-.2f</font> seconds! <font color='#ff0000'>-%-.2f</font> dmg",  (playertime[client] + sm_spawn_protection_time.FloatValue - GetGameTime()), damage );
		if(attacker!=0)
			PrintHintText(attacker, "You can not hurt <font color='#00ff00'>%N</font> yet.\n<font color='#ff0000'>%-.2f</font> seconds left.", client, (playertime[client] + sm_spawn_protection_time.FloatValue) - GetGameTime());
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client, bool nobots = false )
{ 
	if ( !( 1 <= client <= MaxClients ) || !IsClientConnected(client) || (nobots && IsFakeClient(client))) 
		return false; 
	return IsClientInGame(client); 
}
