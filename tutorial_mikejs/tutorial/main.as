int prcYesIcon;
int prcShockIcon;
int prcShellIcon;
int[] defrosts(maxClients);
uint[] lastShotTime(maxClients);
int[] playerSTAT_PROGRESS_SELFdelayed(maxClients);
uint[] playerLastTouch(maxClients);
bool[] spawnNextRound(maxClients);
//String[] defrostMessage(maxClients);
bool doRemoveRagdolls = false;

bool GT_Command(cClient @client, String &cmdString, String &argsString, int argc) {
	if(cmdString == "asdf") {
		cInfoBeacon(@client.getEnt(), "asdf");

		return true;
	}

	if(cmdString == "classaction1") {
		activateNearestInfoBeacon(@client);

		return true;
	}
	
	if(cmdString == "gametype") {
		String response = "";
		Cvar fs_game("fs_game", "", 0);
		String manifest = gametype.get_manifest();
		response += "\n";
		response += "Gametype " + gametype.get_name() + " : " + gametype.get_title() + "\n";
		response += "----------------\n";
		response += "Version: " + gametype.get_version() + "\n";
		response += "Author: " + gametype.get_author() + "\n";
		response += "Mod: " + fs_game.get_string() + (manifest.length() > 0 ? " (manifest: " + manifest + ")" : "") + "\n";
		response += "----------------\n";
		G_PrintMsg(client.getEnt(), response);
		return true;
	}

	return false;
}

bool GT_UpdateBotStatus(cEntity @ent) {
	// TODO: remove?

	return GENERIC_UpdateBotStatus(ent);
}

cEntity @GT_SelectSpawnPoint(cEntity @self) {
	// select a spawning point for a player
	// TODO: remove?
	// maybe add support for duel vs bot or whatever

	return GENERIC_SelectBestRandomSpawnPoint(self, "info_player_deathmatch");
}

String @GT_ScoreboardMessage(uint maxlen) {
	// TODO: remove?

	String scoreboardMessage = "";
	String entry;
	cTeam @team;
	cEntity @ent;
	int i, t, readyIcon;

	for(t = TEAM_ALPHA; t < GS_MAX_TEAMS; t++) {
		@team = @G_GetTeam(t);
		// &t = team tab, team tag, team score (doesn't apply), team ping (doesn't apply)
		entry = "&t " + t + " " + team.stats.score + " " + team.ping + " ";

		if(scoreboardMessage.len() + entry.len() < maxlen) {
			scoreboardMessage += entry;
		}

		for(i = 0; @team.ent(i) != null; i++) {
			@ent = @team.ent(i);

			readyIcon = ent.client.isReady() ? prcYesIcon : 0;

			int playerID = (ent.isGhosting() && (match.getState() == MATCH_STATE_PLAYTIME)) ? -(ent.get_playerNum() + 1) : ent.get_playerNum();

			if(gametype.get_isInstagib()) {
				// "Name Clan Score Ping R"
				entry = "&p " + playerID + " " + ent.client.get_clanName() + " "
					+ ent.client.stats.score + " " +
					+ ent.client.ping + " " + readyIcon + " ";
			} else {
				int carrierIcon;
				if(ent.client.inventoryCount(POWERUP_QUAD) > 0) {
					carrierIcon = prcShockIcon;
				} else if(ent.client.inventoryCount(POWERUP_SHELL) > 0) {
					carrierIcon = prcShellIcon;
				} else {
					carrierIcon = 0;
				}

				// "Name Clan Score Frags Ping C R"
				entry = "&p " + playerID + " " + ent.client.get_clanName() + " "
					+ ent.client.stats.score + " " + ent.client.stats.frags + " "
					+ ent.client.ping + " " + carrierIcon + " " + readyIcon + " ";
			}

			if(scoreboardMessage.len() + entry.len() < maxlen) {
				scoreboardMessage += entry;
			}
		}
	}

	return scoreboardMessage;
}

void GT_updateScore(cClient @client) {
	// TODO: remove?
	
	if(@client != null) {
		if(gametype.get_isInstagib()) {
			client.stats.setScore(client.stats.frags + defrosts[client.get_playerNum()]);
		} else {
			client.stats.setScore(int(client.stats.totalDamageGiven * 0.01) + defrosts[client.get_playerNum()]);
		}
	}
}

void GT_scoreEvent(cClient @client, String &score_event, String &args) {
	// Some game actions trigger score events. These are events not related to killing
	// oponents, like capturing a flag
	
	// TODO
}

void GT_playerRespawn(cEntity @ent, int old_team, int new_team) {
	// a player is being respawned. This can happen from several ways, as dying, changing team,
	// being moved to ghost state, be placed in respawn queue, being spawned from spawn queue, etc
	
	// TODO: give inventory?

	// auto-select best weapon in the inventory
	if(ent.client.pendingWeapon == WEAP_NONE) {
		ent.client.selectWeapon(-1);
	}

	// add a teleportation effect
	ent.respawnEffect();
}

// Thinking function. Called each frame
void GT_ThinkRules() {
	if(match.scoreLimitHit() || match.timeLimitHit() || match.suddenDeathFinished()) {
		match.launchState(match.getState() + 1);
	}

	GENERIC_Think();

	for(int i = 0; i < maxClients; i++) {
		G_CenterPrintMsg(G_GetClient(i).getEnt(), "");
	}

	infoBeaconThinkAll();
	infoDisplay.think();

	if(match.getState() >= MATCH_STATE_POSTMATCH) {
		return;
	}
}

bool GT_MatchStateFinished(int incomingMatchState) {
	// The game has detected the end of the match state, but it
	// doesn't advance it before calling this function.
	// This function must give permission to move into the next
	// state by returning true.
	
	if(match.getState() <= MATCH_STATE_WARMUP && incomingMatchState > MATCH_STATE_WARMUP && incomingMatchState < MATCH_STATE_POSTMATCH) {
		match.startAutorecord();
	}

	if(match.getState() == MATCH_STATE_POSTMATCH) {
		match.stopAutorecord();
	}

	return true;
}

void GT_MatchStateStarted() {
	// the match state has just moved into a new state. Here is the
	// place to set up the new state rules
	
	switch(match.getState()) {
		case MATCH_STATE_WARMUP:
			gametype.pickableItemsMask = gametype.spawnableItemsMask;
			gametype.dropableItemsMask = gametype.spawnableItemsMask;

			GENERIC_SetUpWarmup();

			for(int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++) {
				gametype.setTeamSpawnsystem(team, SPAWNSYSTEM_INSTANT, 0, 0, false);
			}

			break;

		case MATCH_STATE_COUNTDOWN:
			gametype.pickableItemsMask = 0;
			gametype.dropableItemsMask = 0;

			GENERIC_SetUpCountdown();

			break;

		case MATCH_STATE_PLAYTIME:
			gametype.pickableItemsMask = gametype.spawnableItemsMask;
			gametype.dropableItemsMask = gametype.spawnableItemsMask;

			GENERIC_SetUpMatch();

			// set spawnsystem type to not respawn the players when they die
			for(int team = TEAM_PLAYERS; team < GS_MAX_TEAMS; team++) {
				gametype.setTeamSpawnsystem(team, SPAWNSYSTEM_HOLD, 0, 0, true);
			}

			break;

		case MATCH_STATE_POSTMATCH:
			gametype.pickableItemsMask = 0;
			gametype.dropableItemsMask = 0;

			GENERIC_SetUpEndMatch();

			break;

		default:
			break;
	}
}

void GT_Shutdown() {
	// the gametype is shutting down cause of a match restart or map change
}

void GT_SpawnGametype() {
	// The map entities have just been spawned. The level is initialized for
	// playing, but nothing has yet started.
}

void GT_InitGametype() {
	// Important: This function is called before any entity is spawned, and
	// spawning entities from it is forbidden. ifyou want to make any entity
	// spawning at initialization do it in GT_SpawnGametype, which is called
	// right after the map entities spawning.
	
	gametype.set_title("tutorial test");
	gametype.set_version("0.01");
	gametype.set_author("Mike^4JS");

	gametype.spawnableItemsMask = IT_WEAPON | IT_AMMO | IT_ARMOR | IT_POWERUP | IT_HEALTH;
	if(gametype.get_isInstagib()) {
		gametype.spawnableItemsMask &= ~uint(G_INSTAGIB_NEGATE_ITEMMASK);
	}

	gametype.respawnableItemsMask = gametype.spawnableItemsMask;
	gametype.dropableItemsMask = gametype.spawnableItemsMask;
	gametype.pickableItemsMask = gametype.spawnableItemsMask | gametype.dropableItemsMask;

	gametype.isTeamBased = false;
	gametype.isRace = false;
	gametype.hasChallengersQueue = false;
	gametype.maxPlayersPerTeam = 0;

	gametype.ammoRespawn = 20;
	gametype.armorRespawn = 25;
	gametype.weaponRespawn = 15;
	gametype.healthRespawn = 25;
	gametype.powerupRespawn = 90;
	gametype.megahealthRespawn = 20;
	gametype.ultrahealthRespawn = 60;
	gametype.readyAnnouncementEnabled = false;

	gametype.scoreAnnouncementEnabled = true;
	gametype.countdownEnabled = true;
	gametype.mathAbortDisabled = false;
	gametype.shootingDisabled = false;
	gametype.infiniteAmmo = false;
	gametype.canForceModels = true;
	gametype.canShowMinimap = true;
	gametype.teamOnlyMinimap = true;

	gametype.spawnpointRadius = 256;
	if(gametype.get_isInstagib()) {
		gametype.spawnpointRadius *= 2;
	}

	// set spawnsystem type to instant while players join
	for(int t = TEAM_PLAYERS; t < GS_MAX_TEAMS; t++) {
		gametype.setTeamSpawnsystem(t, SPAWNSYSTEM_INSTANT, 0, 0, false);
	}

	// define the scoreboard layout
	if(gametype.get_isInstagib()) {
		G_ConfigString(CS_SCB_PLAYERTAB_LAYOUT, "%n 112 %s 52 %i 52 %l 48 %p 18");
		G_ConfigString(CS_SCB_PLAYERTAB_TITLES, "Name Clan Score Ping R");
	} else {
		G_ConfigString(CS_SCB_PLAYERTAB_LAYOUT, "%n 112 %s 52 %i 52 %i 52 %l 48 %p 18 %p 18");
		G_ConfigString(CS_SCB_PLAYERTAB_TITLES, "Name Clan Score Frags Ping C R");
	}

	// precache images that can be used by the scoreboard
	prcYesIcon = G_ImageIndex("gfx/hud/icons/vsay/yes");
	prcShockIcon = G_ImageIndex("gfx/hud/icons/powerup/quad");
	prcShellIcon = G_ImageIndex("gfx/hud/icons/powerup/warshell");

	// add commands
	G_RegisterCommand("gametype");

	G_RegisterCommand("asdf");
	G_RegisterCommand("classaction1");

	// add callvotes

	if(!G_FileExists("configs/server/gametypes/" + gametype.get_name() + ".cfg")) {
		String config;
		// the config file doesn't exist or it's empty, create it
		config = "// '" + gametype.get_title() + "' gametype configuration file\n"
			+ "// This config will be executed each time the gametype is started\n"
			+ "\n// " + gametype.get_title() + " specific settings\n"
			+ "\n// map rotation\n"
			+ "set g_maplist \"wdm1 wdm2 wdm3 wdm4 wdm5 wdm6 wdm7 wdm8 wdm9 wdm10 wdm11 wdm12 wdm13 wdm14 wdm15 wdm16 wdm17\" // list of maps in automatic rotation\n"
			+ "set g_maprotation \"1\"   // 0 = same map, 1 = in order, 2 = random\n"
			+ "\n// game settings\n"
			+ "set g_scorelimit \"15\"\n"
			+ "set g_timelimit \"0\"\n"
			+ "set g_warmup_enabled \"1\"\n"
			+ "set g_warmup_timelimit \"1.5\"\n"
			+ "set g_match_extendedtime \"0\"\n"
			+ "set g_allow_falldamage \"1\"\n"
			+ "set g_allow_selfdamage \"1\"\n"
			+ "set g_allow_teamdamage \"1\"\n"
			+ "set g_allow_stun \"1\"\n"
			+ "set g_teams_maxplayers \"0\"\n"
			+ "set g_teams_allow_uneven \"0\"\n"
			+ "set g_countdown_time \"5\"\n"
			+ "set g_maxtimeouts \"3\" // -1 = unlimited\n"
			+ "set g_challengers_queue \"0\"\n"
			+ "\necho \"" + gametype.get_name() + ".cfg executed\"\n";
		// G_WriteFile("configs/server/gametypes/" + gametype.get_name() + ".cfg", config);
		// TODO: let's not write a config yet...
		G_Print("Created default config file for '" + gametype.get_name() + "'\n");
		G_CmdExecute("exec configs/server/gametypes/" + gametype.get_name() + ".cfg silent");
	}
	G_Print("Gametype '" + gametype.get_title() + "' initialized\n");

	initMedia();
}
