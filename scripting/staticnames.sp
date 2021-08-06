#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

StringMap g_Stringmap;
char g_Filepath[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = "Static Names",
	author = "FAQU",
	description = "Applies static names to given SteamIDs",
	version = "1.1",
	url = "https://github.com/FAQU2"
};

public void OnPluginStart()
{
	g_Stringmap = new StringMap();
	BuildPath(Path_SM, g_Filepath, sizeof(g_Filepath), "configs/static-names.cfg");
	HookEvent("player_changename", Event_PlayerChangename);
}

public void OnMapStart()
{
	g_Stringmap.Clear();
	
	KeyValues kv = new KeyValues("Static Names");
	
	if (!kv.ImportFromFile(g_Filepath))
	{
		CreateExample(kv);
		return;
	}
	
	if (!kv.GotoFirstSubKey())
	{
		CreateExample(kv);
		return;
	}
	
	char steamid[32];
	char name[MAX_NAME_LENGTH];
	
	do
	{
		if (!kv.GetSectionName(steamid, sizeof(steamid)))
		{
			LogError("Error reading SteamID from file.");
			continue;
		}
		
		if (steamid[6] == 'X') // is example
		{
			continue;
		}
		
		kv.GetString("name", name, sizeof(name));
		TrimString(name);
		
		if (name[0] == '\0') // empty string
		{
			LogError("Error reading name from key %s", steamid);
			continue;
		}
		
		int accountid = Steam2ToAccountID(steamid);
		
		char key[32];
		IntToString(accountid, key, sizeof(key));
		
		g_Stringmap.SetString(key, name);
	}
	while (kv.GotoNextKey());
	
	delete kv;
	
	// useful if plugin gets reloaded
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		StaticName(client, view_as<Event>(INVALID_HANDLE));
	}
}

public void Event_PlayerChangename(Event event, const char[] eventname, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!IsFakeClient(client))
	{
		StaticName(client, event);
	}
}

void StaticName(int client, Event event)
{
	int accountid = GetSteamAccountID(client);
		
	char key[32];
	IntToString(accountid, key, sizeof(key));
		
	char namestatic[32];
		
	if (g_Stringmap.GetString(key, namestatic, sizeof(namestatic)))
	{
		char name[MAX_NAME_LENGTH];
		
		if (!event)
		{
			GetClientName(client, name, sizeof(name));
		}
		else event.GetString("newname", name, sizeof(name));
			
		if (!StrEqual(name, namestatic))
		{
			SetClientInfo(client, "name", namestatic);
		}
	}
}

void CreateExample(KeyValues kv)
{
	kv.JumpToKey("STEAM_X:Y:Z", true);
	kv.SetString("name", "Example");
	kv.Rewind();
	kv.ExportToFile(g_Filepath);
	delete kv;
}

int Steam2ToAccountID(const char[] steam2)
{
	return StringToInt(steam2[10]) * 2 + steam2[8] - 48;
}