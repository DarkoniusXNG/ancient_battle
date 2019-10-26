var GridCategories = FindDotaHudElement('GridCategories');

function FindDotaHudElement(panel) {
	return $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse(panel);
}

function InitHeroSelection()  {
	//$.Msg(GridCategories.GetChildCount())
	var i = 0;

	while (i < GridCategories.GetChildCount()) {
		//$.Msg(GridCategories.GetChild(i))
		//$.Msg(GridCategories.GetChild(i).FindChildTraverse("HeroList"))
		//$.Msg(GridCategories.GetChild(i).FindChildTraverse("HeroList").GetChildCount())

		for (var j = 0; j < GridCategories.GetChild(i).FindChildTraverse("HeroList").GetChildCount(); j++) {
			if (GridCategories.GetChild(i).FindChildTraverse("HeroList").GetChild(j)) {
				var hero_panel = GridCategories.GetChild(i).FindChildTraverse("HeroList").GetChild(j).GetChild(0).GetChild(0);
                //$.Msg(hero_panel)
				if (hero_panel.heroname == "warp_beast") {
					// this works but it makes the portrait static
					var portrait = FindDotaHudElement('HeroInspectInfo').FindChildTraverse('HeroPortrait');
					portrait.style.backgroundImage = 'url("file://{images}/heroes/selection/npc_dota_hero_' + hero_panel.heroname + '.png")';
				    portrait.style.backgroundSize = "100% 100%";
				}
				hero_panel.GetParent().AddClass("HeroCard");
				hero_panel.style.backgroundImage = 'url("file://{images}/heroes/selection/npc_dota_hero_' + hero_panel.heroname + '.png")';
				hero_panel.style.backgroundSize = "100% 100%";
			}
		}

		i++;
	}
}

(function() {
	var PreGame = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("PreGame")
	PreGame.style.opacity = "1";
	PreGame.style.transitionDuration = "0.0s";

	$.Schedule(1.0, InitHeroSelection);
})();