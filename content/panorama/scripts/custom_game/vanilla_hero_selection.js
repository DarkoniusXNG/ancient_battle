/* global $, Game, Players, GameEvents */

function FindDotaHudElement (panel) {
  return $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse(panel);
}

function InitHeroSelection () {
  // $.Msg(GridCategories.GetChildCount())
  let i = 0;
  const GridCategories = FindDotaHudElement('GridCategories');

  while (i < GridCategories.GetChildCount()) {
    // $.Msg(GridCategories.GetChild(i))
    // $.Msg(GridCategories.GetChild(i).FindChildTraverse("HeroList"))
    // $.Msg(GridCategories.GetChild(i).FindChildTraverse("HeroList").GetChildCount())

    for (let j = 0; j < GridCategories.GetChild(i).FindChildTraverse('HeroList').GetChildCount(); j++) {
      if (GridCategories.GetChild(i).FindChildTraverse('HeroList').GetChild(j)) {
        const heroPanel = GridCategories.GetChild(i).FindChildTraverse('HeroList').GetChild(j).GetChild(0).GetChild(0);
        // $.Msg(heroPanel.GetParent())
        heroPanel.GetParent().AddClass('HeroCard');
        heroPanel.style.backgroundImage = 'url("file://{images}/heroes/selection/npc_dota_hero_' + heroPanel.heroname + '.png")';
        heroPanel.style.backgroundSize = '100% 100%';
      }
    }

    i++;
  }
}

// When player clicks on the hero or selects a hero in hero selection
function UpdateHeroSelectionImages () {
  for (const playerId of Game.GetAllPlayerIDs()) {
    if (!(Players.IsSpectator(playerId)) && (Players.IsValidPlayerID(playerId))) {
      const playerInfo = Game.GetPlayerInfo(playerId);
      if (playerInfo) {
        // $.Msg(playerInfo)
        if (playerInfo.player_selected_hero !== '') {
          UpdatePortraitImage(playerInfo.player_selected_hero);
        } else if (playerInfo.possible_hero_selection !== '') {
          UpdatePortraitImage(playerInfo.possible_hero_selection);
        }
      }
    }
  }
}

function UpdatePortraitImage (heroname) {
  if (heroname === 'warp_beast' || heroname === 'sohei' || heroname === 'electrician') {
    // this works but it makes the portrait static
    const portrait = FindDotaHudElement('HeroInspectInfo').FindChildTraverse('HeroPortrait');
    portrait.style.backgroundImage = 'url("file://{images}/heroes/selection/npc_dota_hero_' + heroname + '.png")';
    portrait.style.backgroundSize = '100% 100%';
    $.Schedule(0.1, UpdateTopBarImages);
  }
}

function UpdateTopBarImages () {
  const RadiantPlayers = FindDotaHudElement('RadiantTeamPlayers');
  const DirePlayers = FindDotaHudElement('DireTeamPlayers');
  for (let j = 0; j < RadiantPlayers.GetChildCount(); j++) {
    const heroImageContainer = RadiantPlayers.GetChild(j).FindChildTraverse('HeroImageContainer');
    const topBarHeroImage = heroImageContainer.FindChildTraverse('HeroImage');
    const heroname = topBarHeroImage.heroname;
    if (heroname === 'warp_beast' || heroname === 'sohei' || heroname === 'electrician') {
      // $.Msg(topBarHeroImage)
      OverrideHeroImage(topBarHeroImage);
    }
  }
  for (let j = 0; j < DirePlayers.GetChildCount(); j++) {
    const heroImageContainer = DirePlayers.GetChild(j).FindChildTraverse('HeroImageContainer');
    const topBarHeroImage = heroImageContainer.FindChildTraverse('HeroImage');
    const heroname = topBarHeroImage.heroname;
    if (heroname === 'warp_beast' || heroname === 'sohei' || heroname === 'electrician') {
      // $.Msg(topBarHeroImage)
      OverrideHeroImage(topBarHeroImage);
    }
  }
}

function OverrideHeroImage (panel) {
  if (panel) {
    const name = panel.heroname;
    if (name === 'sohei' || name === 'electrician' || name === 'warp_beast') {
      panel.style.backgroundImage = 'url("file://{images}/heroes/npc_dota_hero_' + name + '.png")';
      panel.style.backgroundSize = '100% 100%';
    }
  }
}

(function () {
  const PreGame = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse('PreGame');
  PreGame.style.opacity = '1';
  PreGame.style.transitionDuration = '0.0s';

  $.Schedule(1.0, InitHeroSelection);
  GameEvents.Subscribe('dota_player_hero_selection_dirty', UpdateHeroSelectionImages);
  GameEvents.Subscribe('dota_player_update_hero_selection', UpdateHeroSelectionImages);
})();
