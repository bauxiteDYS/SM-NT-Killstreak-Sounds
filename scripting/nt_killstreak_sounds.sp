#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define BASE_FOLDER "ntkillstreaksounds"

Handle SoundCookie;

int g_iKillStreak[32+1];

static bool wants_sound[32+1];

static char g_Sounds[][] = {
	"godlike.mp3",
	"holyshit.mp3",
	"ludicrouskill.mp3",
	"monsterkill.mp3",
	"rampage.mp3",
};

public Plugin myinfo = {
	name = "NT killstreak sounds",
	description = "NT killstreak sounds",
	author = "bauxite",
	version = "0.1.3",
	url = "https://github.com/bauxiteDYS/SM-NT-Killstreak-Sounds",
};

public void OnPluginStart()
{
	SoundCookie = RegClientCookie("killstreak_sound_cookie", "killstreak sound cookie", CookieAccess_Public);
	SetCookieMenuItem(SoundTextMenu, SoundCookie, "ace sound");
	
	HookEvent("game_round_start", OnRoundStart, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
}

public void OnMapStart()
{
	char DLBuff[PLATFORM_MAX_PATH];
	char CacheBuff[PLATFORM_MAX_PATH];
	
	for (int i = 0; i < sizeof(g_Sounds); i++)
	{
		Format(DLBuff, sizeof(DLBuff), "sound/%s/%s", BASE_FOLDER, g_Sounds[i]);
		Format(CacheBuff, sizeof(CacheBuff), "%s/%s", BASE_FOLDER, g_Sounds[i]);
			
		AddFileToDownloadsTable(DLBuff);
		PrecacheSound(CacheBuff);
	}
}

public void SoundTextMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_SelectOption) 
	{
		SoundCustomMenu(client);
	}
}

public Action SoundCustomMenu(int client)
{
	Menu menu = new Menu(SoundCustomMenu_Handler, MENU_ACTIONS_DEFAULT);
	menu.AddItem("on", "Enable");
	menu.AddItem("off", "Disable");
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int SoundCustomMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End) 
	{
		delete menu;
	}
	else if (action == MenuAction_Select) 
	{
		int client = param1;
		int selection = param2;

		char option[10];
		menu.GetItem(selection, option, sizeof(option));

		if (StrEqual(option, "on")) 
		{ 
			SetClientCookie(client, SoundCookie, "1");
			wants_sound[client] = true;
		} 
		else 
		{
			SetClientCookie(client, SoundCookie, "0");
			wants_sound[client] = false;
		}
	}
	
	return 0;
}

public void OnClientCookiesCached(int client)
{
	int i_wants_sound;
	char buf_wants_sound[2];
	
	GetClientCookie(client, SoundCookie, buf_wants_sound, 2);
	i_wants_sound = StringToInt(buf_wants_sound);
	
	if(i_wants_sound == 1)
	{
		wants_sound[client] = true;
	}
	else
	{
		wants_sound[client] = false;
	}
}

public void OnClientDisconnect_Post(int client)
{
	wants_sound[client] = false;
}

public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	int client;

	for(client = 1; client <= MaxClients; client++)
	{
		g_iKillStreak[client] = 0;
	}
}

public void OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int client = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(client != victim && GetClientTeam(victim) != GetClientTeam(client))
	{ 
		int streak = ++g_iKillStreak[client];
		
		if(streak == 5)
		{
			char RandomSound[64+1];
		
			Format(RandomSound, 64, "%s/%s", BASE_FOLDER, g_Sounds[GetRandomInt(0, sizeof(g_Sounds)-1)]);
			
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && wants_sound[i])
				{
					EmitSoundToClient(i, RandomSound);
				}
			}
		}
	}
}
