local loaded = false
local warning = false
local PR = CBW_PowerCards

PR.PreThinkFrame = function()
	for player in players.iterate
		player.justtossedflag = false
		player.pc_cmdlast = player.pc_cmd or 0
		player.pc_cmd = 0
		if player.playerstate == PST_LIVE and not(player.spectator)
		and not(player.powers[pw_nocontrol] or P_PlayerInPain(player))
		and player.gotpowercard and player.gotpowercard.valid
			local card = player.gotpowercard
			local item = PR.Item[card.item]
			if item.flags&PCF_NOSPIN and player.cmd.buttons&BT_SPIN
				player.pc_cmd = $|BT_SPIN
				player.cmd.buttons = $&~BT_SPIN
			end
		end
	end
end