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
	version = "1.0"
};

public void OnPluginStart()
{
	stringmap = new StringMap();
	
	BuildPath(Path_SM, filepath, sizeof(filepath), "configs/static-names.cfg");
	HookEvent("player_changename", Event_PlayerChangename);
}

public void OnMapStart()
{
	stringmap.Clear();
	
	KeyValues kv = new KeyValues("Static Names");
	
	if (!kv.ImportFromFile(filepath))
	{
		SetFailState("Error importing file %s", filepath);
	}
	
	if (!kv.GotoFirstSubKey())
	{
		SetFailState("Error reading from file %s (could not read the first sub key)", filepath);
	}
	
	char steamid[32];
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
		RemovePrefix(steamid);
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
	
	char steamid[32];
	char namestatic[MAX_NAME_LENGTH];
	
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	RemovePrefix(steamid);
	
	if (stringmap.GetString(steamid, namestatic, sizeof(namestatic)))
	{
		SetClientInfo(client, "name", namestatic);
	}
}

public void Event_PlayerChangename(Event event, const char[] eventname, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsFakeClient(client))
	{
		return;
	}
	
	char steamid[32];
	char namestatic[MAX_NAME_LENGTH];
	
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	RemovePrefix(steamid);
	
	if (stringmap.GetString(steamid, namestatic, sizeof(namestatic)))
	{
		char newname[MAX_NAME_LENGTH];
		event.GetString("newname", newname, sizeof(newname));
		
		if (!StrEqual(newname, namestatic))
		{
			SetClientInfo(client, "name", namestatic);
		}
	}
}

void RemovePrefix(char steamid[32])
{
	ReplaceString(steamid, sizeof(steamid), "STEAM_0:0:", "");
	ReplaceString(steamid, sizeof(steamid), "STEAM_0:1:", "");
	ReplaceString(steamid, sizeof(steamid), "STEAM_1:0:", "");
	ReplaceString(steamid, sizeof(steamid), "STEAM_1:1:", "");
}