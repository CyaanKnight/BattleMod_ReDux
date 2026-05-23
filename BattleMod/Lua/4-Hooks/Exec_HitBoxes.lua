local B = CBW_Battle

addHook("MobjThinker", B.BattleHitboxThink, MT_BATTLEHITBOX)
addHook("MobjMoveCollide", B.BattleHitboxCollision, MT_BATTLEHITBOX)
addHook("MobjCollide", B.BattleHitboxCollision, MT_BATTLEHITBOX)
addHook("MobjRemoved", B.BattleHitboxRemoved, MT_BATTLEHITBOX)
