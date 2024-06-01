local B = CBW_Battle

local y_rest = 200
local y_offscreen = 0
local bouncetics = 50
local waittics = 20
local width = 256
local height = 128
local scrolldelay = TICRATE*2
local scrolltics = TICRATE
local scrolldist = 100
local animtime = TICRATE*4

local drawscroll = function(v,player,cam,x,y,patch,scroll,scrollspeed,bottom)
	local scrolltime = FixedSqrt(min(scrolldelay,leveltime)*FRACUNIT/scrolldelay)
	scrollspeed = FixedMul(scrolltime,$*FRACUNIT)
	local uncovertime = max(leveltime-scrolldelay,0)
	local uncoveramt = FRACUNIT*max(scrolltics-uncovertime,0)/scrolltics
	if bottom == true
		y = B.FixedLerp($,100,uncoveramt)
	else
		y = B.FixedLerp($,-28,uncoveramt)
	end
	
	patch = v.cachePatch($ or "CHECKER1")
	if scroll == "right"
		for n = 1, (320/width)+3
			local x = x+(((leveltime*scrollspeed/FRACUNIT)%width)+width*(n-3))
			v.draw(x,y,patch,0)
		end
	elseif scroll == "left"
		for n = 1, (320/width)+3
			local x = x-(((leveltime*scrollspeed/FRACUNIT)%width)+width*(n-3))
			v.draw(x,y,patch,0)
		end
	end
end
B.TitleHUD = function(v,player,cam)
	//Texture scrolling
	local offset = 32
	local o = offset
	local o1 = -100
	local o2 = 150
	local m1 = 1
	local d1 = 16
	local m2 = 1
	local d2 = 12
	drawscroll(v,player,cam,0,o1-o*m1/d1,"CHECKER7","left",1,false)
	drawscroll(v,player,cam,0,o2+o*m2/d2,"CHECKER1","right",2,true)
	o = $+offset
	m1 = $+1
	m2 = $+1
	drawscroll(v,player,cam,0,o1-o*m1/d1,"CHECKER3","right",3,false)
	drawscroll(v,player,cam,0,o2+o*m2/d2,"CHECKER4","left",1,true)
	o = $+offset
	m1 = $+1
	m2 = $+1
	drawscroll(v,player,cam,0,o1-o*m1/d1,"CHECKER8","left",2,false)
	drawscroll(v,player,cam,0,o2+o*m2/d2,"CHECKERA","right",3,true)
	//Logo
	if leveltime >= waittics
		local x = 160*FRACUNIT
		local y = y_rest*FRACUNIT
		local time = leveltime-waittics
		if time < bouncetics
			local lerpamt = FRACUNIT*(bouncetics-time)/bouncetics
			local osc = cos(FixedAngle(lerpamt*360))
			local scroll = FixedMul(osc, lerpamt*(y_rest-y_offscreen))
			y = $-scroll
		end
		//Add minor oscillation
		y = $-cos(FixedAngle(FRACUNIT*3*leveltime))*5
		local patch
		if leveltime%animtime == 1
		or leveltime%animtime == 5
			patch = v.cachePatch("LOGO280B")
		elseif leveltime%animtime == 2
		or leveltime%animtime == 4
			patch = v.cachePatch("LOGO280C")
		elseif leveltime%animtime == 3
			patch = v.cachePatch("LOGO280D")
		else
			patch = v.cachePatch("LOGO280A")
		end
		v.drawScaled(x,y,FRACUNIT,patch,0)
	end
	//Debug
-- 	v.drawString(0,0,leveltime,0,"left")
-- 	v.drawString(0,0,tostring(B.BattleCampaign()),0,"left")
end