#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#pragma semicolon 1
#pragma newdecls required

float g_fCmdTime[MAXPLAYERS+1] = {0.0, ...};
ConVar sm_spawn_protection_time;
	
public Plugin myinfo = 
{
	name = "[CS:GO] Spawn protection", 
	author = "IT-KiLLER", 
	description = "Players can not be damaged in a few seconds after spawn.", 
	version = "1.0", 
	url = "https://github.com/it-killer"
}

public void OnPluginStart()
{
	sm_spawn_protection_time  = CreateConVar("sm_spawn_protection_time", "15", "Spawn protection time (0-180)", _, true, 0.0, true, 180.0);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Pre);
	for(int client = 1; client <= MaxClients; client++)
		if(IsClientInGame(client))
			OnClientPutInServer(client);
}

public void OnClientDisconnect_Post(int client)
{
	g_fCmdTime[client] = 0.0;
}

	
public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_fCmdTime[client] = GetGameTime() + sm_spawn_protection_time.FloatValue;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor,float &damage, int &damagetype)
{
	if(!IsValidClient(client)) return Plugin_Continue;

	if (!client || g_fCmdTime[client] > GetGameTime())
	{
		PrintHintText(client, "You are protected for another %-.2f seconds.!\nDamanage -%-.2f ",  (g_fCmdTime[client] - GetGameTime()), damage );
		if(attacker!=0)
			PrintHintText(attacker, "You can not hurt '%N' yet", client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client, bool nobots = false )
{ 
	if ( !( 1 <= client <= MaxClients ) || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false; 
	}
	return IsClientInGame(client); 
}  

