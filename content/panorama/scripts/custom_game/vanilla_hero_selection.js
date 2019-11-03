function FindDotaHudElement(panel) {
	return $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse(panel);
}

function InitHeroSelection() {
	//$.Msg(GridCategories.GetChildCount())
	var i = 0;
	var GridCategories = FindDotaHudElement("GridCategories");

	while (i < GridCategories.GetChildCount()) {
		//$.Msg(GridCategories.GetChild(i))
		//$.Msg(GridCategories.GetChild(i).FindChildTraverse("HeroList"))
		//$.Msg(GridCategories.GetChild(i).FindChildTraverse("HeroList").GetChildCount())

		for (var j = 0; j < GridCategories.GetChild(i).FindChildTraverse("HeroList").GetChildCount(); j++) {
			if (GridCategories.GetChild(i).FindChildTraverse("HeroList").GetChild(j)) {
				var hero_panel = GridCategories.GetChild(i).FindChildTraverse("HeroList").GetChild(j).GetChild(0).GetChild(0);
				//$.Msg(hero_panel.GetParent())
				hero_panel.GetParent().AddClass("HeroCard");
				hero_panel.style.backgroundImage = 'url("file://{images}/heroes/selection/npc_dota_hero_' + hero_panel.heroname + '.png")';
				hero_panel.style.backgroundSize = "100% 100%";
			}
		}

		i++;
	}
}
// When player clicks on the hero or selects a hero in hero selection
function UpdateHeroSelectionImages() {
	var playerId;
	for(playerId of Game.GetAllPlayerIDs()){
		if(!(Players.IsSpectator(playerId)) && (Players.IsValidPlayerID(playerId))){
			var playerInfo = Game.GetPlayerInfo(playerId);
			if (playerInfo){
				//$.Msg(playerInfo)
				if (playerInfo.player_selected_hero !== ""){
					UpdatePortraitImage(playerInfo.player_selected_hero);
				}
				else if (playerInfo.possible_hero_selection !== "") {
					UpdatePortraitImage(playerInfo.possible_hero_selection);
				}
			}
		}
	}
}

function UpdatePortraitImage(heroname) {
	if (heroname == "warp_beast" || heroname == "sohei" || heroname == "electrician") {
		// this works but it makes the portrait static
		var portrait = FindDotaHudElement("HeroInspectInfo").FindChildTraverse("HeroPortrait");
		portrait.style.backgroundImage = 'url("file://{images}/heroes/selection/npc_dota_hero_' + heroname + '.png")';
		portrait.style.backgroundSize = "100% 100%";
	}
}

function UpdateTopBarImages(){
	var RadiantPlayers = FindDotaHudElement("RadiantTeamPlayers");
	var DirePlayers = FindDotaHudElement("DireTeamPlayers");
	for (var j = 0; j < RadiantPlayers.GetChildCount(); j++) {
		var hero_image_container = RadiantPlayers.GetChild(j).FindChildTraverse("HeroImageContainer");
		var top_bar_hero_image = hero_image_container.FindChildTraverse("HeroImage");
		var heroname = top_bar_hero_image.heroname;
		if (heroname == "warp_beast" || heroname == "sohei" || heroname == "electrician") {
			//$.Msg(top_bar_hero_image)
		}
	}
	for (var j = 0; j < DirePlayers.GetChildCount(); j++) {
		var hero_image_container = DirePlayers.GetChild(j).FindChildTraverse("HeroImageContainer");
		var top_bar_hero_image = hero_image_container.FindChildTraverse("HeroImage");
		var heroname = top_bar_hero_image.heroname;
		if (heroname == "warp_beast" || heroname == "sohei" || heroname == "electrician") {
			//$.Msg(top_bar_hero_image)
		}
	}
}

(function() {
	var PreGame = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("PreGame")
	PreGame.style.opacity = "1";
	PreGame.style.transitionDuration = "0.0s";

	$.Schedule(1.0, InitHeroSelection);
	GameEvents.Subscribe("dota_player_hero_selection_dirty", UpdateHeroSelectionImages);
	GameEvents.Subscribe("dota_player_update_hero_selection", UpdateHeroSelectionImages);
})();