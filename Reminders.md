# Reminders
1) Don't use ~=nil in conditions. false and nil are only boolean falses. 0 is not.
2) Always do ReleaseParticleIndex(particleID) after you are done with a particle.
DestroyParticle(particleID) if particle is not being destroyed by itself.
3) Instead of using :GetTeam() use :GetTeamNumber().
4) Avoid using EmitSoundOn  and StopSoundOn -> they don't respect Fog of War. Use unit:EmitSound("") instead.
5) Use enums wherever you can.
6) Avoid using + for bit values (unless they are userdata/uint64). Use bit.bor(v1,v2,v3,...).
7) If a spell is dealing physical damage, you need a damage flag: DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
8) DeclareFunctions() and CheckState() don't need: 'local funcs = {...}' or 'local state = {...}', just do 'return {...}' 
if there are no special conditions.
9) Don't do 'return nil', doing 'return' is enough.

