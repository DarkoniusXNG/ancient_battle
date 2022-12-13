/* global $, GameUI, Players, GameEvents, CustomNetTables */

let skip = false;

// Recieves a list of entities to replace the current selection
function SelectionNew (msg) {
  const entities = msg.entities;
  // $.Msg("SelectionNew ", entities)
  for (const i in entities) {
    if (i === 1) {
      GameUI.SelectUnit(entities[i], false);
    } else {
      GameUI.SelectUnit(entities[i], true);
    }
  }
  $.Schedule(0.03, SendSelectedEntities);
}

// Recieves a list of entities to add to the current selection
function SelectionAdd (msg) {
  const entities = msg.entities;
  // $.Msg("SelectionAdd ", entities)
  for (const i in entities) {
    GameUI.SelectUnit(entities[i], true);
  }
  $.Schedule(0.03, SendSelectedEntities);
}

// Removes a list of entities from the current selection
function SelectionRemove (msg) {
  const removeEntities = msg.entities;
  // $.Msg("SelectionRemove ", removeEntities)
  const selectedEntities = GetSelectedEntities();
  for (const i in removeEntities) {
    const index = selectedEntities.indexOf(removeEntities[i]);
    if (index > -1) {
      selectedEntities.splice(index, 1);
    }
  }

  if (selectedEntities.length === 0) {
    SelectionReset();
    return;
  }

  for (const j in selectedEntities) {
    if (j === 0) {
      GameUI.SelectUnit(selectedEntities[j], false);
    } else {
      GameUI.SelectUnit(selectedEntities[j], true);
    }
  }
  $.Schedule(0.03, SendSelectedEntities);
}

// Fall back to the default selection
function SelectionReset (msg) {
  const playerID = Players.GetLocalPlayer();
  const heroIndex = Players.GetPlayerHeroEntityIndex(playerID);
  GameUI.SelectUnit(heroIndex, false);
  $.Schedule(0.03, SendSelectedEntities);
}

// Filter & Sending
function OnUpdateSelectedUnit () {
  // $.Msg( "OnUpdateSelectedUnit ", Players.GetLocalPlayerPortraitUnit() );
  if (skip === true) {
    skip = false;
    return;
  }

  // Skips units from the selected group
  SelectionFilter(GetSelectedEntities());

  $.Schedule(0.03, SendSelectedEntities);
}

// Updates the list of selected entities on server for this player
function SendSelectedEntities () {
  GameEvents.SendCustomGameEventToServer('selection_update', { entities: GetSelectedEntities() });
}

// Local player shortcut
function GetSelectedEntities () {
  return Players.GetSelectedEntities(Players.GetLocalPlayer());
}

// Returns an index of an override defined on lua with npcHandle:SetSelectionOverride(reselect_unit)
function GetSelectionOverride (entityIndex) {
  const table = CustomNetTables.GetTableValue('selection', entityIndex);
  return table ? table.entity : -1;
}

function OnUpdateQueryUnit () {
  // $.Msg( "OnUpdateQueryUnit ", Players.GetQueryUnit(Players.GetLocalPlayer()));
}

function SelectionFilter (entityList) {
  for (let i = 0; i < entityList.length; i++) {
    const overrideEntityIndex = GetSelectionOverride(entityList[i]);
    if (overrideEntityIndex !== -1) {
      GameUI.SelectUnit(overrideEntityIndex, false);
    }
  }
}

(function () {
  // Custom event listeners
  GameEvents.Subscribe('selection_new', SelectionNew);
  GameEvents.Subscribe('selection_add', SelectionAdd);
  GameEvents.Subscribe('selection_remove', SelectionRemove);
  GameEvents.Subscribe('selection_reset', SelectionReset);

  // Built-In Dota client events
  GameEvents.Subscribe('dota_player_update_selected_unit', OnUpdateSelectedUnit);
  GameEvents.Subscribe('dota_player_update_query_unit', OnUpdateQueryUnit);
})();
