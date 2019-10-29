function FindDotaHudElement(panel) {
	return $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse(panel);
}

function OverrideHeroImage(panel){
	if (panel) {
		//$.Msg(panel2.heroname)
		panel.style.backgroundImage = 'url("file://{images}/heroes/selection/npc_dota_hero_' + panel.heroname + '.png")';
		panel.style.backgroundSize = "100% 100%";
	}
}

function OverrideHeroImagesForTeam(team){
	if (team) {
		for (i=0; i < DOTALimits_t.DOTA_MAX_TEAM_PLAYERS-1; i++)
		{
			var top_bar_panel = FindDotaHudElement(team + "Player" + i);
			if (top_bar_panel && Players.IsValidPlayerID(i)){
				var panel = top_bar_panel.FindChildTraverse("HeroImage");
				OverrideHeroImage(panel)
			}
		}
	}
}

function OverrideTopBarHeroImages(){
	OverrideHeroImagesForTeam("Radiant");
	OverrideHeroImagesForTeam("Dire");
}

GameEvents.Subscribe("npc_spawned", OverrideTopBarHeroImages)