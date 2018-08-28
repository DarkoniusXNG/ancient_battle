"use strict";

function UpdateTimer()
{
	var gameTime = Game.GetGameTime();
	var transitionTime = Game.GetStateTransitionTime();

	var timerValue = Math.max(0, Math.floor( transitionTime - gameTime ));
	
	if ( Game.GameStateIsAfter(DOTA_GameState.DOTA_GAMERULES_STATE_HERO_SELECTION ) )
	{
		timerValue = 0;
	}
	$("#TimerPanel").SetDialogVariableInt("timer_seconds", timerValue);

	var banPhaseInstructions = $("#BanPhaseInstructions");
	var pickPhaseInstructions = $("#PickPhaseInstructions");

	var bIsInBanPhase = Game.IsInBanPhase();

	banPhaseInstructions.SetHasClass("Visible", bIsInBanPhase == true);
	pickPhaseInstructions.SetHasClass("Visible", bIsInBanPhase == false);

	$.Schedule( 0.1, UpdateTimer );
}

(function()
{
	var timerPanel = $.CreatePanel("Panel", $.GetContextPanel(), "TimerPanel");
	timerPanel.BLoadLayout( "file://{resources}/layout/custom_game/hero_select_overlay_timer.xml", false, false );

	UpdateTimer();
})();

