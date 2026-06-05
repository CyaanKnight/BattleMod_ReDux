
--PowerCards HUD

/*
	Handles gameplay HUD info.
	For Debug HUD info, see Debug.lua
*/

local B = CBW_Battle
local PR = CBW_PowerCards

local newhud_offset = 20
local bar_offset = 20

PR.ItemHUD = function(v, player, cam)
	if player.playerstate != PST_LIVE
	or player.gotpowercard == nil
	or not(player.gotpowercard.valid)
		return
	end
	
	local xoffset = 20
	local yoffset = 166
	local flags = V_HUDTRANS|V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_PERPLAYER
	local align = "thin"
	local card = player.gotpowercard
	local item = PR.Item[card.item]

	if B.Console.FindVarString("battleconfig_hud", {"New", "Minimal"}) then
		yoffset = $-newhud_offset
	end
	
	//Draw text
	local text = item.name or "<Card with No Name>"
	if not(leveltime%4)
		text = "\x82"..$
	end
	v.drawString(xoffset+12,yoffset,text,flags,align)
	//Draw sprite
	local state = states[item.state]
	local patch = v.getSpritePatch(state.sprite, state.frame)
	local scale = FRACUNIT>>2
	v.drawScaled(xoffset*FRACUNIT,(yoffset+6)*FRACUNIT,scale,patch,flags)
	//Draw health
	v.drawFill(xoffset+12,yoffset+bar_offset,32,6)
	v.drawFill(xoffset+12,yoffset+bar_offset,32*card.health/item.health,6,0)
	if PR.CV_Debug.value
		v.drawString(xoffset-16,yoffset-18,"HP: "..card.health.."/"..item.health,V_HUDTRANSHALF|V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_PERPLAYER,align)		
	end
end

PR.EventHUD = function(v, player, cam)
	local xoffset = 100
	local yoffset = 180
	local flags = V_HUDTRANS|V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_PERPLAYER
	local align = "thin"

	if B.Console.FindVarString("battleconfig_hud", {"New", "Minimal"}) then
		yoffset = $-(newhud_offset+2)
	end

	for player in players.iterate
		local card = player.gotpowercard
		if not(card) continue end
		local item = PR.Item[card.item]
		if not(item.flags&PCF_HUDWARNING) continue end
		//Draw card
		local state = states[item.state]
		local patch = v.getSpritePatch(state.sprite, state.frame)
		local scale = FRACUNIT>>3
		v.drawScaled((xoffset+8)*FRACUNIT,(yoffset)*FRACUNIT,scale,patch,flags)
		//Draw player head icon
		local scale = FRACUNIT>>1
		v.drawScaled(
			(xoffset+0)*FRACUNIT,
			(yoffset+0)*FRACUNIT,
			scale,
			v.getSprite2Patch(player.mo.skin, SPR2_LIFE),
			flags,
			v.getColormap(nil, player.mo.color)
		)
		//Draw health
		if leveltime&1
			v.drawString(xoffset,yoffset,card.health/TICRATE,flags,align)		
		end
		//Set offset for next event
		xoffset = $+20
	end
end
