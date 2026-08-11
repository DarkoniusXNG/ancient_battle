/* global $, Game, Players, GameEvents */

function FindDotaHudElement (panel) {
  return $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse(panel);
}

function InitHeroSelection () {
  let i = 0;
  const GridCategories = FindDotaHudElement('GridCategories');

  while (i < GridCategories.GetChildCount()) {
    let HeroListContainer = GridCategories.GetChild(i).FindChildTraverse('HeroList');

    for (let j = 0; j < HeroListContainer.GetChildCount(); j++) {
      if (HeroListContainer.GetChild(j)) {
        const heroPanel = HeroListContainer.GetChild(j).GetChild(0).GetChild(0);
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
          UpdatePortraitImage(playerInfo.player_selected_hero, false);
        } else if (playerInfo.possible_hero_selection !== '') {
          UpdatePortraitImage(playerInfo.possible_hero_selection, true);
        }
      }
    }
  }
}

function UpdatePortraitImage (heroname, notPickedYet) {
  if (heroname === 'warp_beast' || heroname === 'sohei' || heroname === 'electrician') {
    // this works but it makes the portrait static
    const portrait = FindDotaHudElement('HeroInspectInfo').FindChildTraverse('HeroPortrait');
    portrait.style.backgroundImage = 'url("file://{images}/heroes/selection/npc_dota_hero_' + heroname + '.png")';
    portrait.style.backgroundSize = '100% 100%';
    $.Schedule(0.1, function() {
		UpdateTopBarImages(notPickedYet);
    });
  }
}

function UpdateTopBarImages (notPickedYet) {
  const RadiantPlayers = FindDotaHudElement('RadiantTeamPlayers');
  const DirePlayers = FindDotaHudElement('DireTeamPlayers');
  OverrideHeroImages(RadiantPlayers, notPickedYet);
  OverrideHeroImages(DirePlayers, notPickedYet);
}

function OverrideHeroImages (playersPanel, notPickedYet) {
  for (let j = 0; j < playersPanel.GetChildCount(); j++) {
    const heroImageContainer = playersPanel.GetChild(j).FindChildTraverse('HeroImageContainer');
    const topBarHeroImage = heroImageContainer.FindChildTraverse('HeroImage');
    if (topBarHeroImage) {
      const name = topBarHeroImage.heroname;
      if (name === 'sohei' || name === 'electrician' || name === 'warp_beast') {
        topBarHeroImage.style.backgroundImage = 'url("file://{images}/heroes/npc_dota_hero_' + name + '.png")';
        topBarHeroImage.style.backgroundSize = '100% 100%';
        if (notPickedYet) {
          topBarHeroImage.style.backgroundImgOpacity = '0.5';
        }
      }
    }
  }
}

(function () {
  const PreGame = FindDotaHudElement('PreGame');
  PreGame.style.opacity = '1';
  PreGame.style.transitionDuration = '0.0s';

  $.Schedule(1.0, InitHeroSelection);
  GameEvents.Subscribe('dota_player_hero_selection_dirty', UpdateHeroSelectionImages);
  GameEvents.Subscribe('dota_player_update_hero_selection', UpdateHeroSelectionImages);
})();
