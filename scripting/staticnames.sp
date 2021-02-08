#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

StringMap stringmap;
char filepath[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = "Static Names",
	author = "FAQU",
	version = "1.0.1"
};

public void OnPluginStart()
{
	BuildPath(Path_SM, filepath, sizeof(filepath), "configs/static-names.cfg");
	
	stringmap = new StringMap();
	
	HookEvent("player_changename", Event_PlayerChangename);
}

public void OnMapStart()
{
	stringmap.Clear();
	
	KeyValues kv = new KeyValues("Static Names");
	
	if (!kv.ImportFromFile(filepath))
	{
		CreateExample(kv);
		return;
	}
	
	if (!kv.GotoFirstSubKey())
	{
		CreateExample(kv);
		return;
	}
	
	char steamid[24];
	char name[MAX_NAME_LENGTH];
	
	do
	{
		if (!kv.GetSectionName(steamid, sizeof(steamid)))
		{
			LogError("Error reading steamid from subkey.");
			continue;
		}
		
		kv.GetString("name", name, sizeof(name));
		
		if (StrEqual(name, ""))
		{
			LogError("Error reading name from key \"%s\"", steamid);
			continue;
		}
		
		RemovePrefix(steamid, sizeof(steamid));
		stringmap.SetString(steamid, name);
	}
	while (kv.GotoNextKey());
	
	delete kv;
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	char playername[MAX_NAME_LENGTH];
	GetClientName(client, playername, sizeof(playername));
	
	ApplyStaticName(client, playername);
}

public void Event_PlayerChangename(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsFakeClient(client))
	{
		return;
	}
	
	char playername[MAX_NAME_LENGTH];
	event.GetString("newname", playername, sizeof(playername));
	
	ApplyStaticName(client, playername);
}


void ApplyStaticName(int client, const char[] playername)
{
	char steamid[24];
	char namestatic[MAX_NAME_LENGTH];
	
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	RemovePrefix(steamid, sizeof(steamid));
	
	if (stringmap.GetString(steamid, namestatic, sizeof(namestatic)))
	{
		if (!StrEqual(playername, namestatic))
		{
			SetClientInfo(client, "name", namestatic);
		}
	}
}

void RemovePrefix(char[] steamid, int maxlength)
{
	ReplaceStringEx(steamid, maxlength, "STEAM_0:0:", "");
	ReplaceStringEx(steamid, maxlength, "STEAM_0:1:", "");
	ReplaceStringEx(steamid, maxlength, "STEAM_1:0:", "");
	ReplaceStringEx(steamid, maxlength, "STEAM_1:1:", "");
}

void CreateExample(KeyValues kv)
{
	kv.JumpToKey("STEAM_0:0:11101", true);
	kv.SetString("name", "Example");
	kv.Rewind();
	kv.ExportToFile(filepath);
	delete kv;
}