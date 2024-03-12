#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define BASE_FOLDER "ntkillstreaksounds"

Handle SoundCookie;
Handle StreakTimer;

int g_iKillStreak[32+1];

bool StreakPlayed[32+1][3];
bool SoundCooldown;

char RandomSound[64+1];
bool wants_sound[32+1];

static char g_SoundsSix[][] = {
	"godlike.mp3",
	"godlike_f.mp3",
	"holyshit.mp3",
	"holyshit_f.mp3",
	"ludicrouskill.mp3",
	"monsterkill.mp3",
	"rampage.mp3",
};

static char g_SoundsFor[][] = {
	"dominating_f.mp3",
	"killingspree_f.mp3",
	"multikill_f.mp3",
	"multikill.mp3",
	"ultrakill.mp3",
	"ultrakill_f.mp3",
};

static char g_SoundsAte[][] = {
	"wickedsick_f.mp3",
	"unstoppable_f.mp3",
};

public Plugin myinfo = {
	name = "NT PUB killstreak sounds",
	description = "NT PUB killstreak sounds",
	author = "bauxite",
	version = "0.3.3",
	url = "https://github.com/bauxiteDYS/SM-NT-Killstreak-Sounds",
};

public void OnPluginStart()
{
	SoundCookie = RegClientCookie("killstreak_sound_pub_cookie", "killstreak sound pub cookie", CookieAccess_Public);
	SetCookieMenuItem(SoundTextMenu, SoundCookie, "killstreak sounds");
	
	HookEvent("game_round_start", OnRoundStart, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
}

public void OnMapStart()
{
	LoadSounds();
}

void LoadSounds()
{
	char DLBuff[PLATFORM_MAX_PATH];
	char CacheBuff[PLATFORM_MAX_PATH];
	
	for (int i = 0; i < sizeof(g_SoundsSix); i++)
	{
		Format(DLBuff, sizeof(DLBuff), "sound/%s/%s", BASE_FOLDER, g_SoundsSix[i]);
		Format(CacheBuff, sizeof(CacheBuff), "%s/%s", BASE_FOLDER, g_SoundsSix[i]);
			
		AddFileToDownloadsTable(DLBuff);
		PrecacheSound(CacheBuff);
	}
	
	for (int i = 0; i < sizeof(g_SoundsFor); i++)
	{
		Format(DLBuff, sizeof(DLBuff), "sound/%s/%s", BASE_FOLDER, g_SoundsFor[i]);
		Format(CacheBuff, sizeof(CacheBuff), "%s/%s", BASE_FOLDER, g_SoundsFor[i]);
			
		AddFileToDownloadsTable(DLBuff);
		PrecacheSound(CacheBuff);
	}
	
	for (int i = 0; i < sizeof(g_SoundsAte); i++)
	{
		Format(DLBuff, sizeof(DLBuff), "sound/%s/%s", BASE_FOLDER, g_SoundsAte[i]);
		Format(CacheBuff, sizeof(CacheBuff), "%s/%s", BASE_FOLDER, g_SoundsAte[i]);
			
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
	for(int client = 1; client <= MaxClients; client++)
	{
		g_iKillStreak[client] = 0;
		
		for(int i = 0; i < 3; i++)
		{
			StreakPlayed[client][i] = false;
		}
	}
}

public void OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(victim == 0)
	{
		return;
	}
	
	g_iKillStreak[victim] = 0;
	
	for(int i = 0; i < 3; i++)
	{
		StreakPlayed[victim][i] = false;
	}
	
	if(attacker == 0)
	{
		return;
	}
	
	if(attacker == victim)
	{
		return;
	}
	
	if(GetClientTeam(victim) == GetClientTeam(attacker))
	{ 
		return;
	}
	
	++g_iKillStreak[attacker];
	
	int streak = g_iKillStreak[attacker];
	
	if(streak > 3 && StreakTimer == null)
	{
		StreakTimer = CreateTimer(1.0, CheckStreak, attacker, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action CheckStreak(Handle timer, int attacker)
{
	int streak = g_iKillStreak[attacker];
	
	if(streak < 6 && !StreakPlayed[attacker][0])
	{
		Format(RandomSound, 64, "%s/%s", BASE_FOLDER, g_SoundsFor[GetRandomInt(0, sizeof(g_SoundsFor)-1)]);	
		StreakPlayed[attacker][0] = true;
		PlaySound();
	}
	
	if(streak < 8 && !StreakPlayed[attacker][1])
	{
		Format(RandomSound, 64, "%s/%s", BASE_FOLDER, g_SoundsSix[GetRandomInt(0, sizeof(g_SoundsSix)-1)]);
		StreakPlayed[attacker][1] = true;
		PlaySound();
	}
	
	if(streak >= 8 && !StreakPlayed[attacker][2])
	{
		Format(RandomSound, 64, "%s/%s", BASE_FOLDER, g_SoundsAte[GetRandomInt(0, sizeof(g_SoundsAte)-1)]);
		StreakPlayed[attacker][2] = true;
		PlaySound();
	}
	
	StreakTimer = null;

	return Plugin_Stop;
}

void PlaySound()
{
	if(SoundCooldown)
	{
		return;
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && wants_sound[i])
		{
			EmitSoundToClient(i, RandomSound);
		}
	}
	
	SoundCooldown = true;
	
	CreateTimer(1.5, ResetSoundCooldown, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action ResetSoundCooldown(Handle timer, any data)
{
	SoundCooldown = false;
	
	return Plugin_Stop;
}
