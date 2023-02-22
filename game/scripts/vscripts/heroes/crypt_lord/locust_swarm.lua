
function LocustSwarmStart( event )
    local caster = event.caster
    local ability = event.ability

    --local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
    local duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )
    local locusts = ability:GetLevelSpecialValueFor( "locusts", ability:GetLevel() - 1 )
    local delay_between_locusts = ability:GetLevelSpecialValueFor( "delay_between_locusts", ability:GetLevel() - 1 )
    local unit_name = "undead_crypt_lord_locust"

    -- Initialize the table to keep track of all locusts
    caster.swarm = {}
    LocustDebugPrint("Spawning "..locusts.." locusts")
    for i = 1, locusts do
        Timers:CreateTimer(i * delay_between_locusts, function()
            local unit = CreateUnitByName(unit_name, caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
			unit:SetOwner(caster:GetOwner())
			--unit:SetControllableByPlayer(caster:GetPlayerID(), true)
			unit:AddNewModifier(caster, ability, "modifier_kill", {duration = duration + 10})

            -- The modifier takes care of the logic and particles of each unit
            ability:ApplyDataDrivenModifier(caster, unit, "modifier_locust", {})

            -- Add the spawned unit to the table
            table.insert(caster.swarm, unit)
        end)
    end
end

-- Movement logic for each locust
-- Units have 4 states:
    -- acquiring: transition after completing one target-return cycle.
    -- target_acquired: tracking an enemy or point to collide
    -- returning: After colliding with an enemy, move back to the casters location
    -- end: moving back to the caster to be destroyed
function LocustSwarmPhysics( event )
    local caster = event.caster
    local locust = event.target
    local ability = event.ability
    local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
    --local duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )
    local locusts_speed = ability:GetLevelSpecialValueFor( "locusts_speed", ability:GetLevel() - 1 )
    local locust_damage = ability:GetLevelSpecialValueFor( "locust_damage", ability:GetLevel() - 1 )
    local locust_heal_threshold = ability:GetLevelSpecialValueFor( "locust_heal_threshold", ability:GetLevel() - 1 )
    local max_locusts_on_target = ability:GetLevelSpecialValueFor( "max_locusts_on_target", ability:GetLevel() - 1 )
    local max_distance = ability:GetLevelSpecialValueFor( "max_distance", ability:GetLevel() - 1 )
    local give_up_distance = ability:GetLevelSpecialValueFor( "give_up_distance", ability:GetLevel() - 1 )
    local abilityDamageType = ability:GetAbilityDamageType()
    local abilityTargetType = ability:GetAbilityTargetType()
    local particleName = "particles/units/heroes/hero_weaver/weaver_base_attack_explosion.vpcf"
    local particleNameHeal = "particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta_start_sparks_b.vpcf"

    -- Make the locust a physics unit
    Physics:Unit(locust)

    -- General properties
    locust:PreventDI(true)
    locust:SetAutoUnstuck(false)
    locust:SetNavCollisionType(PHYSICS_NAV_NOTHING)
    locust:FollowNavMesh(false)
    locust:SetPhysicsVelocityMax(locusts_speed)
    locust:SetPhysicsVelocity(locusts_speed * RandomVector(1))
    locust:SetPhysicsFriction(0)
    locust:Hibernate(false)
    locust:SetGroundBehavior(PHYSICS_GROUND_LOCK)

    -- Initial default state
    locust.state = "acquiring"

    -- This is to skip frames
    local frameCount = 0

    -- Store the damage done
    locust.damage_done = 0

    -- Color Debugging for points and paths. Turn it false later!
    --local Debug = false
    local pathColor = Vector(255,255,255) -- White to draw path
    local targetColor = Vector(255,0,0) -- Red for enemy targets
    local idleColor = Vector(0,255,0) -- Green for moving to idling points
    local returnColor = Vector(0,0,255) -- Blue for the return
    local endColor = Vector(0,0,0) -- Back when returning to the caster to end
    local draw_duration = 3

    -- Find one target point at random which will be used for the first acquisition.
    local point = caster:GetAbsOrigin() + RandomVector(RandomInt(radius/2, radius))

    -- This is set to repeat on each frame
    locust:OnPhysicsFrame(function(unit)

        -- Current positions
        local source = caster:GetAbsOrigin()
        local current_position = unit:GetAbsOrigin()

        -- Print the path on Debug mode
        LocustDebugDraw(current_position, pathColor, 0, 2, true, draw_duration)

        local enemies

        -- Use this if skipping frames is needed (--if frameCount == 0 then..)
        frameCount = (frameCount + 1) % 3

        -- Movement and Collision detection are state independent

        -- MOVEMENT
        -- Get the direction
        local diff = point - unit:GetAbsOrigin()
        diff.z = 0
        local direction = diff:Normalized()

        -- Calculate the angle difference
        local angle_difference = RotationDelta(VectorToAngles(unit:GetPhysicsVelocity():Normalized()), VectorToAngles(direction)).y

        -- Set the new velocity
        if math.abs(angle_difference) < 5 then
            -- CLAMP
            local newVel = unit:GetPhysicsVelocity():Length() * direction
            unit:SetPhysicsVelocity(newVel)
        elseif angle_difference > 0 then
            local newVel = RotatePosition(Vector(0,0,0), QAngle(0,10,0), unit:GetPhysicsVelocity())
            unit:SetPhysicsVelocity(newVel)
        else
            local newVel = RotatePosition(Vector(0,0,0), QAngle(0,-10,0), unit:GetPhysicsVelocity())
            unit:SetPhysicsVelocity(newVel)
        end

        -- COLLISION CHECK
        local distance = (point - current_position):Length()
        local collision = distance < 50

        -- MAX DISTANCE CHECK
        local distance_to_caster = (source - current_position):Length()
        if distance > max_distance then
            unit:SetAbsOrigin(source)
            unit.state = "acquiring"
        end

        -- STATE DEPENDENT LOGIC
        -- Damage, Healing and Targeting are state dependent.
        -- Update the point in all frames

        -- Acquiring...
        -- Acquiring -> Target Acquired (enemy or idle point)
        -- Target Acquired... if collision -> Acquiring or Return
        -- Return... if collision -> Acquiring

        -- Acquiring finds new targets and changes state to target_acquired with a current_target if it finds enemies or nil and a random point if there are no enemies
        if unit.state == "acquiring" then

            -- If the unit doesn't have a target locked, find enemies near the caster
			enemies = FindUnitsInRadius(
				caster:GetTeamNumber(),
				source,
				nil,
				radius,
				DOTA_UNIT_TARGET_TEAM_ENEMY,
				abilityTargetType,
				DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
				FIND_ANY_ORDER,
				false
			)

            -- Check the possible enemies, assigning a new one
            local target_enemy
            for _, enemy in pairs(enemies) do

                -- If the enemy this time is different than the last unit.current_target, select it
                -- Also check how many units are locked on this target, if its already max_locusts_on_target, ignore it
                if not enemy.locusts_locked then
                    enemy.locusts_locked = 0
                end

                if not target_enemy and not enemy:IsCustomWardTypeUnit() and enemy ~= unit.current_target and enemy.locusts_locked < max_locusts_on_target then
                    target_enemy = enemy
                    enemy.locusts_locked = enemy.locusts_locked + 1
                end
            end

            -- Keep track of it, set the state to target_acquired
            if target_enemy then
                unit.state = "target_acquired"
                unit.current_target = target_enemy
                point = unit.current_target:GetAbsOrigin()
                LocustDebugPrint("Acquiring -> Enemy Target acquired: "..unit.current_target:GetUnitName())
            -- If no enemies, set the unit to collide with a random point.
            else
                unit.state = "target_acquired"
                unit.current_target = nil
                point = source + RandomVector(RandomInt(radius/2, radius))
                LocustDebugPrint("Acquiring -> Random Point Target acquired")
                LocustDebugDraw(point, idleColor, 100, 25, true, draw_duration)
            end

        -- If the state was to follow a target enemy, it means the unit can perform an attack.
        elseif unit.state == "target_acquired" then

            -- Update the point of the target's current position
            if unit.current_target then
                point = unit.current_target:GetAbsOrigin()
                LocustDebugDraw(point, targetColor, 100, 25, true, draw_duration)

                -- Give up on the target if the distance goes over the give_up_distance
                if distance_to_caster > give_up_distance then
                    unit.state = "acquiring"
                    LocustDebugPrint("Gave up on the target, acquiring a new target.")

                    -- Decrease the locusts_locked counter
                    unit.current_target.locusts_locked = unit.current_target.locusts_locked - 1
                end
            end

            -- Damage and heal
            -- Also set to come back to the caster if the locust_heal_threshold has been dealt
            if collision then

                -- If the target was an enemy and not a point, the unit collided with it
                if unit.current_target ~= nil then

                    -- Damage, units will still try to collide with attack immune targets but the damage wont be applied
                    if not unit.current_target:IsAttackImmune() then
                        local damagePostReduction = ApplyDamage({victim = unit.current_target, attacker = unit, damage_type = abilityDamageType, damage = locust_damage, ability = ability})

                        LocustDebugPrint(locust_damage, damagePostReduction)

                        unit.damage_done = unit.damage_done + damagePostReduction

                        -- Damage particle
                        local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, unit.current_target)
                        ParticleManager:SetParticleControl(particle, 0, unit.current_target:GetAbsOrigin())
                        ParticleManager:SetParticleControlEnt(particle, 3, unit.current_target, PATTACH_POINT_FOLLOW, "attach_hitloc", unit.current_target:GetAbsOrigin(), true)

                        -- Fire Sound on the target unit
                        unit.current_target:EmitSound("Hero_Weaver.SwarmAttach")

                        -- Decrease the locusts_locked counter
                        unit.current_target.locusts_locked = unit.current_target.locusts_locked - 1
                    end

                    -- Send the unit back to return, or keep attacking new targets
                    if unit.damage_done >= locust_heal_threshold then
                        unit.state = "returning"
                        point = source
                        LocustDebugPrint("Returning to caster after dealing ",unit.damage_done)
                    else
                        unit.state = "acquiring"
                        LocustDebugPrint("Attacked but still needs more damage to return: ",unit.damage_done)
                    end

                -- In other case, its a point, reacquire target
                else
                    unit.state = "acquiring"
                    LocustDebugPrint("Attempting to acquire a new target")
                end
            end

        -- If it was a collision on a return (meaning it reached the caster), change to acquiring so it finds a new target
        -- Also heal the caster on each return of a locust
        elseif unit.state == "returning" then

            -- Update the point to the caster's current position
            point = source
            LocustDebugDraw(point, returnColor, 100, 25, true, draw_duration)

            if collision then
                unit.state = "acquiring"

                caster:Heal(locust_heal_threshold, ability)
                LocustDebugPrint("Healed")

                -- Heal particle
                local particle = ParticleManager:CreateParticle(particleNameHeal, PATTACH_ABSORIGIN_FOLLOW, caster)
                ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())

                -- Reset the damage done
                unit.damage_done = 0
            end

        -- if set the state to end, the point is also the caster position, but the units will be removed on collision
        elseif unit.state == "end" then
            point = source
            LocustDebugDraw(point, endColor, 100, 25, true, 2)

            -- Last collision ends the unit
            if collision then
                unit:SetPhysicsVelocity(Vector(0,0,0))
                unit:OnPhysicsFrame(nil)
                unit:RemoveSelf()

				-- Double check to reset all locusts_locked counters when the ability ends
				enemies = FindUnitsInRadius(
					caster:GetTeamNumber(),
					source,
					nil,
					max_distance,
					DOTA_UNIT_TARGET_TEAM_ENEMY,
					abilityTargetType,
					DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
					FIND_ANY_ORDER,
					false
				)

                for _, v in pairs(enemies) do
                    if v and not v:IsNull() then
						v.locusts_locked = nil
					end
                end
            end
        end
    end)
end

-- -- Change the state to end when the modifier is removed
function LocustSwarmEnd( event )
    local caster = event.caster
    local targets = caster.swarm
    -- LocustDebugPrint("End")
    for _, unit in pairs(targets) do
        if unit and IsValidEntity(unit) then
            unit.state = "end"
        end
    end
end

-- -- Kill all units when the owner dies
function LocustSwarmDeath( event )
    local caster = event.caster
    local targets = caster.swarm
    local particleName = "particles/units/heroes/hero_weaver/weaver_base_attack_explosion.vpcf"

    -- LocustDebugPrint("Death")
    for _, unit in pairs(targets) do
        if unit and IsValidEntity(unit) then
            unit:SetPhysicsVelocity(Vector(0,0,0))
            unit:OnPhysicsFrame(nil)

            -- Explosion particle
            local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, unit)
            ParticleManager:SetParticleControl(particle, 0, unit:GetAbsOrigin())
            ParticleManager:SetParticleControlEnt(particle, 3, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(particle)

            -- Kill
            unit:ForceKill(false)
        end
    end
end

local Debug = false
function LocustDebugPrint(...)
    if Debug then
		print('[LocustSwarm] ' .. ...)
	end
end

function LocustDebugDraw(center,vRgb,a,rad,ztest,duration)
    if Debug then
		DebugDrawCircle(center, vRgb, a, rad, ztest, duration)
	end
end

---------------------------------------------------------------------------------------------------

function VectorDistanceSq(v1, v2)
    return (v1.x - v2.x) * (v1.x - v2.x) + (v1.y - v2.y) * (v1.y - v2.y) + (v1.z - v2.z) * (v1.z - v2.z)
end

---------------------------------------------------------------------------------------------------

PHYSICS_VERSION = "1.01"

PHYSICS_NAV_NOTHING = 0
PHYSICS_NAV_HALT = 1
PHYSICS_NAV_SLIDE = 2
PHYSICS_NAV_BOUNCE = 3
PHYSICS_NAV_GROUND = 4

PHYSICS_GROUND_NOTHING = 0
PHYSICS_GROUND_ABOVE = 1
PHYSICS_GROUND_LOCK = 2

COLLIDER_SPHERE = 0
COLLIDER_BOX = 1
COLLIDER_AABOX = 2

PHYSICS_THINK = 0.01

if Physics == nil then
  print ( '[PHYSICS] creating Physics' )
  Physics = {}
  Physics.__index = Physics
end

function IsPhysicsUnit(unit)
  return unit.GetPhysicsVelocity ~= nil
end

function Physics:new( o )
  o = o or {}
  setmetatable( o, Physics )
  return o
end

ColliderProfiles = {}

function ColliderProfiles:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Physics:start()

  if self.thinkEnt == nil then
    self.timers = {}
    self.Colliders = {}
    self.ColliderProfiles = {}
    self.anggrid = nil
    self.offsetX = nil
    self.offsetY = nil
    self.colliderSkipOffset = 0
    self.frameCount = 0

    self.thinkEnt = SpawnEntityFromTableSynchronous("info_target", {targetname="physics_lua_thinker"})
    self.thinkEnt:SetThink("Think", self, "physics", PHYSICS_THINK)
  end
end

function Physics:CreateColliderProfile(name, profile)
  self.ColliderProfiles[name] = ColliderProfiles:new(profile)
  profile.name = name
  return self.ColliderProfiles[name]
end

function Physics:ColliderFromProfile(name, collider)
  return self.ColliderProfiles[name]:new(collider)
end

function Physics:AddCollider(name, collider)
  if type(name) == "table" then
    collider = name
    name = DoUniqueString("collider")
  end

  collider.skipOffset = self.colliderSkipOffset
  self.colliderSkipOffset = self.colliderSkipOffset + 1

  collider.name = name
  self.Colliders[name] = collider
  return collider
end

function Physics:RemoveCollider(name)
  if type(name) == "table" then
    name = name.name
  end

  local collider = self.Colliders[name]
  if collider == nil then
    return
  end
  if collider.unit ~= nil and collider.unit.oColliders[collider.name] ~= nil then
    collider.unit.oColliders[collider.name] = nil
  end


  self.Colliders[name] = nil
end

function Physics:Think()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
    return
  end

  -- Track game time, since the dt passed in to think is actually wall-clock time not simulation time.
  local now = GameRules:GetGameTime()
  --print("now: " .. now)
  if Physics.t0 == nil then
    Physics.t0 = now
  end
  local dt = now - Physics.t0
  Physics.t0 = now

  self.frameCount = self.frameCount + 1

  -- Process timers
  for k,v in pairs(Physics.timers) do
    -- Run the callback
    local status, nextCall = pcall(v.callback, Physics, v)

    -- Make sure it worked
    if status then
      -- Check if it needs to loop
      if nextCall then
        -- Change it's end time
        v.endTime = nextCall
      else
        Physics.timers[k] = nil
      end

      -- Update timer data
      --self:UpdateTimerData()
    else
      -- Nope, handle the error
      Physics.timers[k] = nil
      print('[PHYSICS] Timer error:' .. nextCall)
    end
  end

  if dt > 0 then
    for name,collider in pairs(Physics.Colliders) do
      if collider.skipFrames == 0 or ((self.frameCount + collider.skipOffset) % (collider.skipFrames + 1) == 0) then
        if collider.type == COLLIDER_SPHERE then
          local rad2 = collider.radius * collider.radius
          local unit = collider.unit
          if IsValidEntity(unit) then
            if collider.draw then
              local alpha = 0
              local color = Vector(200,0,0)
              if type(collider.draw) == "table" then
                alpha = collider.draw.alpha or alpha
                color = collider.draw.color or color
              end

              DebugDrawCircle(unit:GetAbsOrigin(), color, alpha, collider.radius, true, .01)
            end

            local ents
            if collider.filter then
              if type(collider.filter) == "table" then
                ents = collider.filter
              else
                local status
                status, ents = pcall(collider.filter, collider)
                if not status then
                  print('[PHYSICS] Collision Filter Failure!: ' .. ents)
                end
              end
            else
              ents = Entities:FindAllInSphere(unit:GetAbsOrigin(), collider.radius + 200)
            end

            for k,v in pairs(ents) do
              if IsValidEntity(v) and IsValidEntity(unit) and v ~= unit and rad2 >= VectorDistanceSq(unit:GetAbsOrigin(), v:GetAbsOrigin()) then
                local status2, test = pcall(collider.test, collider, unit, v)

                if not status2 then
                  print('[PHYSICS] Collision Test Failure!: ' .. test)
                elseif test then
                  if collider.preaction then
                    local status3, action = pcall(collider.preaction, collider, unit, v)
                    if not status3 then
                      print('[PHYSICS] Collision preaction Failure!: ' .. action)
                    end
                  end
                  local status4, action = pcall(collider.action, collider, unit, v)
                  if not status4 then
                    print('[PHYSICS] Collision action Failure!: ' .. action)
                  end
                  if collider.postaction then
                    local status5, action5 = pcall(collider.postaction, collider, unit, v)
                    if not status5 then
                      print('[PHYSICS] Collision postaction Failure!: ' .. action5)
                    end
                  end
                end
              end
            end
          else
            Physics:RemoveCollider(name)
          end
        elseif collider.type == COLLIDER_BOX then
          -- box collider
          local box = collider.box
          if box.recalculate or box.ad2 == nil then
            collider.box = Physics:PrecalculateBox(box)
          end

          if collider.draw then
            local alpha = 5
            local color = Vector(200,0,0)
            if type(collider.draw) == "table" then
              alpha = collider.draw.alpha or alpha
              color = collider.draw.color or color
            end

            if not collider.box.drawAngle then
               Physics:PrecalculateBoxDraw(collider.box)
            end

            DebugDrawBoxDirection(box.drawMins, Vector(0,0,0), box.drawMaxs - box.drawMins, RotatePosition(Vector(0,0,0), QAngle(0,box.drawAngle,0), Vector(1,0,0)), color, alpha, .01)
          end

          local ents
          if collider.filter then
            if type(collider.filter) == "table" then
              ents = collider.filter
            else
              local status
              status, ents = pcall(collider.filter, collider)
              if not status then
                print('[PHYSICS] Collision Filter Failure!: ' .. ents)
              end
            end
          else
            ents = Entities:FindAllInSphere(box.center, box.radius + 200)
          end

          for k,v in pairs(ents) do
            if IsValidEntity(v) then
              local pos = v:GetAbsOrigin()
              if (pos.z >= box.zMin and pos.z <= box.zMax) then
                pos.z = 0
                local am = pos - box.a
                local amDotAb = am:Dot(box.ab)
                if amDotAb > 0 and amDotAb < box.ab2 then
                  local amDotAd = am:Dot(box.ad)
                  if amDotAd > 0 and amDotAd < box.ad2 then
                    --inside
                    local status, test = pcall(collider.test, collider, v)

                    if not status then
                      print('[PHYSICS] Collision Test Failure!: ' .. test)
                    elseif test then
                      if collider.preaction then
                        local status2, action = pcall(collider.preaction, collider, box, v)
                        if not status2 then
                          print('[PHYSICS] Collision preaction Failure!: ' .. action)
                        end
                      end
                      local status3, action = pcall(collider.action, collider, box, v)
                      if not status3 then
                        print('[PHYSICS] Collision action Failure!: ' .. action)
                      end
                      if collider.postaction then
                        local status4, action4 = pcall(collider.postaction, collider, box, v)
                        if not status4 then
                          print('[PHYSICS] Collision postaction Failure!: ' .. action4)
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        elseif collider.type == COLLIDER_AABOX then
          -- box collider
          local box = collider.box
          if box.recalculate or box.xMin == nil then
            collider.box = Physics:PrecalculateAABox(box)
          end

          if collider.draw then
            local alpha = 5
            local color = Vector(200,0,0)
            if type(collider.draw) == "table" then
              alpha = collider.draw.alpha or alpha
              color = collider.draw.color or color
            end

            DebugDrawBox(Vector(0,0,0), Vector(box.xMin, box.yMin, box.zMin), Vector(box.xMax, box.yMax, box.zMax), color.x, color.y, color.z, alpha, .01)
          end

          local ents
          if collider.filter then
            if type(collider.filter) == "table" then
              ents = collider.filter
            else
              local status
              status, ents = pcall(collider.filter, collider)
              if not status then
                print('[PHYSICS] Collision Filter Failure!: ' .. ents)
              end
            end
          else
            ents = Entities:FindAllInSphere(box.center, box.radius + 200)
          end

          for k,v in pairs(ents) do
            if IsValidEntity(v) then
              local pos = v:GetAbsOrigin()
              if (pos.x >= box.xMin and pos.x <= box.xMax and pos.y >= box.yMin and pos.y <= box.yMax and pos.z >= box.zMin and pos.z <= box.zMax) then

                --inside
                local status, test = pcall(collider.test, collider, v)

                if not status then
                  print('[PHYSICS] Collision Test Failure!: ' .. test)
                elseif test then
                  if collider.preaction then
                    local status2, action = pcall(collider.preaction, collider, box, v)
                    if not status2 then
                      print('[PHYSICS] Collision preaction Failure!: ' .. action)
                    end
                  end
                  local status3, action = pcall(collider.action, collider, box, v)
                  if not status3 then
                    print('[PHYSICS] Collision action Failure!: ' .. action)
                  end
                  if collider.postaction then
                    local status4, action4 = pcall(collider.postaction, collider, box, v)
                    if not status4 then
                      print('[PHYSICS] Collision postaction Failure!: ' .. action4)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  return PHYSICS_THINK
end

function Physics:CreateTimer(name, args)
  if not args.endTime or not args.callback then
    print("Invalid timer created: "..name)
    return
  end

  Physics.timers[name] = args
end

function Physics:RemoveTimer(name)
  Physics.timers[name] = nil
end

function Physics:RemoveTimers(killAll)
  local timers = {}

  if not killAll then
    for k,v in pairs(Physics.timers) do
      if v.persist then
        timers[k] = v
      end
    end
  end

  Physics.timers = timers
end

function Physics:GenerateAngleGrid()
  local anggrid = {}
  local worldMin = Vector(GetWorldMinX(), GetWorldMinY(), 0)
  local worldMax = Vector(GetWorldMaxX(), GetWorldMaxY(), 0)

  print(worldMin)
  print(worldMax)

  local boundX1 = GridNav:WorldToGridPosX(worldMin.x)
  local boundX2 = GridNav:WorldToGridPosX(worldMax.x)
  local boundY1 = GridNav:WorldToGridPosX(worldMin.y)
  local boundY2 = GridNav:WorldToGridPosX(worldMax.y)
  local offsetX = boundX1 * -1 + 1
  local offsetY = boundY1 * -1 + 1

  print(boundX1 .. " -- " .. boundX2)
  print(boundY1 .. " -- " .. boundY2)
  print(offsetX)
  print(offsetY)

  local vecs = {
    {vec = Vector(0,1,0):Normalized(), x=0,y=1},-- N
    {vec = Vector(1,1,0):Normalized(), x=1,y=1}, -- NE
    {vec = Vector(1,0,0):Normalized(), x=1,y=0}, -- E
    {vec = Vector(1,-1,0):Normalized(), x=1,y=-1}, -- SE
    {vec = Vector(0,-1,0):Normalized(), x=0,y=-1}, -- S
    {vec = Vector(-1,-1,0):Normalized(), x=-1,y=-1}, -- SW
    {vec = Vector(-1,0,0):Normalized(), x=-1,y=0}, -- W
    {vec = Vector(-1,1,0):Normalized(), x=-1,y=1} -- NW
  }

  print('----------------------')

  anggrid[1] = {}
  for j=boundY1,boundY2 do
    anggrid[1][j + offsetY] = -1
  end
  anggrid[1][boundY2 + offsetY] = -1

  for i=boundX1+1,boundX2-1 do
    anggrid[i+offsetX] = {}
    anggrid[i+offsetX][1] = -1
    for j=(boundY1+1),boundY2-1 do
      local position = Vector(GridNav:GridPosToWorldCenterX(i), GridNav:GridPosToWorldCenterY(j), 0)
      local blocked = not GridNav:IsTraversable(position) or GridNav:IsBlocked(position) --or (pseudoGNV[i] ~= nil and pseudoGNV[i][j])
      local seg = 0
      local sum = Vector(0,0,0)
      local count = 0
      local inseg = false

      if blocked then
        for k=1,#vecs do
          local vec = vecs[k].vec
          local xoff = vecs[k].x
          local yoff = vecs[k].y
          local pos = Vector(GridNav:GridPosToWorldCenterX(i+xoff), GridNav:GridPosToWorldCenterY(j+yoff), 0)
          local blo = not GridNav:IsTraversable(pos) or GridNav:IsBlocked(pos) --or (pseudoGNV[i+xoff] ~= nil and pseudoGNV[i+xoff][j+yoff])

          if not blo then
            count = count + 1
            inseg = true
            sum = sum + vec
          else
            if inseg then
              inseg = false
              seg = seg + 1
            end
          end
        end

        if seg > 1 then
          print ('OVERSEG x=' .. i .. ' y=' .. j)
          anggrid[i+offsetX][j+offsetY] = -1
        elseif count > 5 then
          print ('PROTRUDE x=' .. i .. ' y=' .. j)
          anggrid[i+offsetX][j+offsetY] = -1
        elseif count == 0 then
          anggrid[i+offsetX][j+offsetY] = -1
        else
          sum = sum:Normalized()
          local angle = math.floor((math.acos(Vector(1,0,0):Dot(sum:Normalized()))/ math.pi * 180))
          if sum.y < 0 then
            angle = -1 * angle
          end
          anggrid[i+offsetX][j+offsetY] = angle
        end
      else
        anggrid[i+offsetX][j+offsetY] = -1
      end
    end
    anggrid[i+offsetX][boundY2+offsetY] = -1
  end

  anggrid[boundX2+offsetX] = {}
  for j=boundY1,boundY2 do
    anggrid[boundX2+offsetX][j+offsetY] = -1
  end
  anggrid[boundX2+offsetX][boundY2+offsetY] = -1

  print('--------------')
  print(#anggrid)
  print(#anggrid[1])
  print(#anggrid[2])
  print(#anggrid[3])

  Physics:AngleGrid(anggrid)
end

function Physics:AngleGrid( anggrid, angoffsets )
  self.anggrid = anggrid
  print('[PHYSICS] Angle Grid Set')
  local worldMin = Vector(GetWorldMinX(), GetWorldMinY(), 0)
  --local worldMax = Vector(GetWorldMaxX(), GetWorldMaxY(), 0)
  local boundX1 = GridNav:WorldToGridPosX(worldMin.x)
  --local boundX2 = GridNav:WorldToGridPosX(worldMax.x)
  local boundY1 = GridNav:WorldToGridPosX(worldMin.y)
  --local boundY2 = GridNav:WorldToGridPosX(worldMax.y)
  local offsetX = boundX1 * -1 + 1
  local offsetY = boundY1 * -1 + 1
  self.offsetX = offsetX
  self.offsetY = offsetY

  if angoffsets then
    self.offsetX = math.abs(angoffsets.x) + 1
    self.offsetY = math.abs(angoffsets.y) + 1
  end
end

function Physics:CalcSlope(pos, unit, dir)

  dir = Vector(dir.x, dir.y, 0):Normalized()
  local f = GetGroundPosition(pos + dir, unit)
  local b = GetGroundPosition(pos - dir, unit)

  return (f - b):Normalized()
end

function Physics:CalcNormal(pos, unit, scale)
  scale = scale or 1
  local nscale = -1 * scale
  --local diag = 0.70710678118 * scale
  --local ndiag = -1 * diag

  local zl =  GetGroundPosition(pos + Vector(nscale,0,0), unit).z
  local zr =  GetGroundPosition(pos + Vector(scale,0,0), unit).z
  local zu =  GetGroundPosition(pos + Vector(0,scale,0), unit).z
  local zd =  GetGroundPosition(pos + Vector(0,nscale,0), unit).z

  --[[local zld = GetGroundPosition(pos + Vector(ndiag,ndiag,0), unit).z
  local zlu = GetGroundPosition(pos + Vector(ndiag,diag,0), unit).z
  local zrd = GetGroundPosition(pos + Vector(diag,ndiag,0), unit).z
  local zru = GetGroundPosition(pos + Vector(diag,diag,0), unit).z]]

  --print (Vector(zld - zlu, zrd - zru, 2*scale))
  --print (Vector(zl - zr, zd - zu, 2*scale))
  --return (RotatePosition(Vector(0,0,0), QAngle(0,45,0), Vector(zld - zlu, zrd - zru, 2*scale)) + Vector(zl - zr, zd - zu, 2*scale)):Normalized()
  return Vector(zl - zr, zd - zu, 2*scale):Normalized()
end

function Physics:Unit(unit)
  if IsPhysicsUnit(unit) then
    if Convars:GetBool("developer") then
      unit:StopPhysicsSimulation()
    else
      return
    end
  end
  function unit:StopPhysicsSimulation () -- luacheck: ignore
    Physics.timers[unit.PhysicsTimerName] = nil
    unit.bStarted = false
  end
  function unit:StartPhysicsSimulation () -- luacheck: ignore
    Physics.timers[unit.PhysicsTimerName] = unit.PhysicsTimer
    unit.PhysicsTimer.endTime = GameRules:GetGameTime()
    unit.PhysicsLastPosition = unit:GetAbsOrigin()
    unit.PhysicsLastTime = GameRules:GetGameTime()
    unit.vLastVelocity = Vector(0,0,0)
    unit.vSlideVelocity = Vector(0,0,0)
    unit.bStarted = true
  end

  function unit:SetPhysicsVelocity (velocity) -- luacheck: ignore
    unit.vVelocity = velocity / 30
    if unit.nVelocityMax > 0 and unit.vVelocity:Length() > unit.nVelocityMax then
      unit.vVelocity = unit.vVelocity:Normalized() * unit.nVelocityMax
    end

    if unit.bStarted and unit.bHibernating then
      Physics.timers[unit.PhysicsTimerName] = unit.PhysicsTimer
      unit.PhysicsTimer.endTime = GameRules:GetGameTime()
      unit.PhysicsLastPosition = unit:GetAbsOrigin()
      unit.PhysicsLastTime = GameRules:GetGameTime()
      unit.vLastVelocity = Vector(0,0,0)
      unit.vSlideVelocity = Vector(0,0,0)
      unit.bHibernating = false
    end
  end
  function unit:AddPhysicsVelocity (velocity) -- luacheck: ignore
    unit.vVelocity = unit.vVelocity + velocity / 30
    if unit.nVelocityMax > 0 and unit.vVelocity:Length() > unit.nVelocityMax then
      unit.vVelocity = unit.vVelocity:Normalized() * unit.nVelocityMax
    end

    if unit.bStarted and unit.bHibernating then
      Physics.timers[unit.PhysicsTimerName] = unit.PhysicsTimer
      unit.PhysicsTimer.endTime = GameRules:GetGameTime()
      unit.PhysicsLastPosition = unit:GetAbsOrigin()
      unit.PhysicsLastTime = GameRules:GetGameTime()
      unit.vLastVelocity = Vector(0,0,0)
      unit.vSlideVelocity = Vector(0,0,0)
      unit.bHibernating = false
    end
  end

  function unit:SetPhysicsVelocityMax (velocityMax) -- luacheck: ignore
    unit.nVelocityMax = velocityMax / 30
  end
  function unit:GetPhysicsVelocityMax () -- luacheck: ignore
    return unit.vVelocity * 30
  end

  function unit:SetPhysicsAcceleration (acceleration) -- luacheck: ignore
    unit.vAcceleration = acceleration / 900

    if unit.bStarted and unit.bHibernating then
      Physics.timers[unit.PhysicsTimerName] = unit.PhysicsTimer
      unit.PhysicsTimer.endTime = GameRules:GetGameTime()
      unit.PhysicsLastPosition = unit:GetAbsOrigin()
      unit.PhysicsLastTime = GameRules:GetGameTime()
      unit.vLastVelocity = Vector(0,0,0)
      unit.vSlideVelocity = Vector(0,0,0)
      unit.bHibernating = false
    end
  end
  function unit:AddPhysicsAcceleration (acceleration) -- luacheck: ignore
    unit.vAcceleration = unit.vAcceleration + acceleration / 900

    if unit.bStarted and unit.bHibernating then
      Physics.timers[unit.PhysicsTimerName] = unit.PhysicsTimer
      unit.PhysicsTimer.endTime = GameRules:GetGameTime()
      unit.PhysicsLastPosition = unit:GetAbsOrigin()
      unit.PhysicsLastTime = GameRules:GetGameTime()
      unit.vLastVelocity = Vector(0,0,0)
      unit.vSlideVelocity = Vector(0,0,0)
      unit.bHibernating = false
    end
  end

  function unit:SetPhysicsFriction (percFriction, flatFriction) -- luacheck: ignore
    unit.fFriction = percFriction
    unit.fFlatFriction = (flatFriction or (unit.fFlatFriction*30))/30
  end

  function unit:GetPhysicsVelocity () -- luacheck: ignore
    return unit.vVelocity  * 30
  end
  function unit:GetPhysicsAcceleration () -- luacheck: ignore
    return unit.vAcceleration * 900
  end
  function unit:GetPhysicsFriction () -- luacheck: ignore
    return unit.fFriction, unit.fFlatFriction*30
  end

  function unit:FollowNavMesh (follow) -- luacheck: ignore
    unit.bFollowNavMesh = follow
  end
  function unit:IsFollowNavMesh () -- luacheck: ignore
    return unit.bFollowNavMesh
  end

  function unit:SetGroundBehavior (ground) -- luacheck: ignore
    unit.nLockToGround = ground
  end
  function unit:GetGroundBehavior () -- luacheck: ignore
    return unit.nLockToGround
  end

  function unit:SetSlideMultiplier (slideMultiplier) -- luacheck: ignore
    unit.fSlideMultiplier = slideMultiplier
  end
  function unit:GetSlideMultiplier () -- luacheck: ignore
    return unit.fSlideMultiplier
  end

  function unit:Slide (slide) -- luacheck: ignore
    unit.bSlide = slide

    if unit.bStarted and unit.bHibernating then
      Physics.timers[unit.PhysicsTimerName] = unit.PhysicsTimer
      unit.PhysicsTimer.endTime = GameRules:GetGameTime()
      unit.PhysicsLastPosition = unit:GetAbsOrigin()
      unit.PhysicsLastTime = GameRules:GetGameTime()
      unit.vLastVelocity = Vector(0,0,0)
      unit.vSlideVelocity = Vector(0,0,0)
      unit.bHibernating = false
    end
  end
  function unit:IsSlide () -- luacheck: ignore
    return unit.bSlide
  end

  function unit:PreventDI (prevent) -- luacheck: ignore
    unit.bPreventDI = prevent
    if not prevent and unit:HasModifier("modifier_rooted") then
      unit:RemoveModifierByName("modifier_rooted")
    end
  end
  function unit:IsPreventDI () -- luacheck: ignore
    return unit.bPreventDI
  end

  function unit:SetNavCollisionType (collisionType) -- luacheck: ignore
    unit.nNavCollision = collisionType
  end
  function unit:GetNavCollisionType () -- luacheck: ignore
    return unit.nNavCollision
  end

  function unit:OnPhysicsFrame(fun) -- luacheck: ignore
    unit.PhysicsFrameCallback = fun
  end

  function unit:SetVelocityClamp (clamp) -- luacheck: ignore
    unit.fVelocityClamp = clamp / 30
  end

  function unit:GetVelocityClamp () -- luacheck: ignore
    return unit.fVelocityClamp * 30
  end

  function unit:Hibernate (hibernate) -- luacheck: ignore
    unit.bHibernate = hibernate
  end

  function unit:IsHibernate () -- luacheck: ignore
    return unit.bHibernate
  end

  function unit:DoHibernate () -- luacheck: ignore
    Physics.timers[unit.PhysicsTimerName] = nil
    unit.bHibernating = true
  end

  function unit:OnHibernate(fun) -- luacheck: ignore
    unit.PhysicsHibernateCallback = fun
  end

  function unit:OnPreBounce(fun) -- luacheck: ignore
    unit.PhysicsOnPreBounce = fun
  end

  function unit:OnBounce(fun) -- luacheck: ignore
    unit.PhysicsOnBounce = fun
  end

  function unit:OnPreSlide(fun) -- luacheck: ignore
    unit.PhysicsOnPreSlide = fun
  end

  function unit:OnSlide(fun) -- luacheck: ignore
    unit.PhysicsOnSlide = fun
  end

  function unit:AdaptiveNavGridLookahead (adaptive) -- luacheck: ignore
    unit.bAdaptiveNavGridLookahead = adaptive
  end

  function unit:IsAdaptiveNavGridLookahead () -- luacheck: ignore
    return unit.bAdaptiveNavGridLookahead
  end

  function unit:SetNavGridLookahead (lookahead) -- luacheck: ignore
    unit.nNavGridLookahead = lookahead
  end

  function unit:GetNavGridLookahead () -- luacheck: ignore
    return unit.nNavGridLookahead
  end

  function unit:SkipSlide (frames) -- luacheck: ignore
    unit.nSkipSlide = frames or 1
  end

  function unit:SetRebounceFrames ( rebounce ) -- luacheck: ignore
    unit.nMaxRebounce = rebounce
    unit.nRebounceFrames = 0
  end

  function unit:GetRebounceFrames () -- luacheck: ignore
    unit.nRebounceFrames = 0
    return unit.nMaxRebounce
  end

  function unit:GetLastGoodPosition () -- luacheck: ignore
    return unit.vLastGoodPosition
  end

  function unit:SetStuckTimeout (timeout) -- luacheck: ignore
    unit.nStuckTimeout = timeout
    unit.nStuckFrames = 0
  end
  function unit:GetStuckTimeout () -- luacheck: ignore
    unit.nStuckFrames = 0
    return unit.nStuckTimeout
  end

  function unit:SetAutoUnstuck (unstuck) -- luacheck: ignore
    unit.bAutoUnstuck = unstuck
  end
  function unit:GetAutoUnstuck () -- luacheck: ignore
    return unit.bAutoUnstuck
  end

  function unit:SetBounceMultiplier (bounce) -- luacheck: ignore
    unit.fBounceMultiplier = bounce
  end
  function unit:GetBounceMultiplier () -- luacheck: ignore
    return unit.fBounceMultiplier
  end

  function unit:GetTotalVelocity() -- luacheck: ignore
    if unit.bStarted and not unit.bHibernating then
      return unit.vTotalVelocity
    else
      return Vector(0,0,0)
    end
  end

  function unit:GetColliders() -- luacheck: ignore
    return unit.oColliders
  end

  function unit:RemoveCollider(name) -- luacheck: ignore
    if name == nil then
      local i, v = next(unit.oColliders,  nil) -- luacheck: ignore v
      if i == nil then
        return
      end
      name = unit.oColliders[i].name
    elseif type(name) == "table" then
      name = name.name
    end
    Physics:RemoveCollider(name)
  end

  function unit:AddCollider(name, collider) -- luacheck: ignore
    local coll = Physics:AddCollider(name, collider)
    coll.unit = unit
    unit.oColliders[coll.name] = coll
    return coll
  end

  function unit:AddColliderFromProfile(name, profile, collider) -- luacheck: ignore
    if profile == nil then
      profile = name
      name = DoUniqueString("collider")
    elseif type(profile) == "table" then
      collider = profile
      profile = name
      name = DoUniqueString("collider")
    end
    local coll = Physics:AddCollider(name, Physics:ColliderFromProfile(profile, collider))
    coll.unit = unit
    unit.oColliders[coll.name] = coll
    return coll
  end

  function unit:GetMass() -- luacheck: ignore
    return unit.fMass
  end

  function unit:SetMass(mass) -- luacheck: ignore
    unit.fMass = mass
  end

  function unit:GetNavGroundAngle() -- luacheck: ignore
    return math.acos(unit.fNavGroundAngle) * 180 / math.pi
  end

  function unit:SetNavGroundAngle(angle) -- luacheck: ignore
    unit.fNavGroundAngle = math.cos(angle * math.pi / 180)
  end

  function unit:CutTrees(cut) -- luacheck: ignore
    unit.bCutTrees = cut
  end

  function unit:IsCutTrees() -- luacheck: ignore
    return unit.bCutTrees
  end

  function unit:IsInSimulation() -- luacheck: ignore
    return unit.bStarted
  end

  function unit:SetBoundOverride(bound) -- luacheck: ignore
    unit.fBoundOverride = bound
  end

  function unit:GetBoundOverride() -- luacheck: ignore
    return unit.fBoundOverride
  end

  function unit:ClearStaticVelocity() -- luacheck: ignore
    unit.staticForces = {}
    unit.staticSum = Vector(0,0,0)
  end

  function unit:SetStaticVelocity(name, velocity) -- luacheck: ignore
    if unit.staticForces[name] ~= nil then
      unit.staticSum = unit.staticSum - unit.staticForces[name]
    end
    unit.staticForces[name] = velocity / 30
    unit.staticSum = unit.staticSum + unit.staticForces[name]

    if unit.bStarted and unit.bHibernating then
      Physics.timers[unit.PhysicsTimerName] = unit.PhysicsTimer
      unit.PhysicsTimer.endTime = GameRules:GetGameTime()
      unit.PhysicsLastPosition = unit:GetAbsOrigin()
      unit.PhysicsLastTime = GameRules:GetGameTime()
      unit.vLastVelocity = Vector(0,0,0)
      unit.vSlideVelocity = Vector(0,0,0)
      unit.bHibernating = false
    end
  end

  function unit:GetStaticVelocity(name) -- luacheck: ignore
    if name == nil then
      return unit.staticSum
    else
      return unit.staticForces[name]
    end
  end

  function unit:AddStaticVelocity(name, velocity) -- luacheck: ignore
    if unit.staticForces[name] == nil then
      unit.staticForces[name] = velocity / 30
      unit.staticSum = unit.staticSum + unit.staticForces[name]
    else
      unit.staticSum = unit.staticSum - unit.staticForces[name]
      unit.staticForces[name] = unit.staticForces[name] + velocity / 30
      unit.staticSum = unit.staticSum + unit.staticForces[name]
    end

    if unit.bStarted and unit.bHibernating then
      Physics.timers[unit.PhysicsTimerName] = unit.PhysicsTimer
      unit.PhysicsTimer.endTime = GameRules:GetGameTime()
      unit.PhysicsLastPosition = unit:GetAbsOrigin()
      unit.PhysicsLastTime = GameRules:GetGameTime()
      unit.vLastVelocity = Vector(0,0,0)
      unit.vSlideVelocity = Vector(0,0,0)
      unit.bHibernating = false
    end
  end

  function unit:SetPhysicsFlatFriction(flatFriction) -- luacheck: ignore
    unit.fFlatFriction = flatFriction / 30
  end

  function unit:GetPhysicsFlatFriction() -- luacheck: ignore
    return unit.fFlatFriction
  end

  unit.lastGoodGround = Vector(0,0,0)
  unit.PhysicsTimerName = DoUniqueString('phys')
  Physics:CreateTimer(unit.PhysicsTimerName, {
    endTime = GameRules:GetGameTime(),
    useGameTime = true,
    callback = function(reflex, args)
      local prevTime = unit.PhysicsLastTime
      if not IsValidEntity(unit) then
        return
      end
      local curTime = GameRules:GetGameTime()
      local prevPosition = unit.PhysicsLastPosition
      local position = unit:GetAbsOrigin()
      local slideVelocity = Vector(0,0,0)
      local lastVelocity = unit.vLastVelocity
      unit.vTotalVelocity = (position - prevPosition) / (curTime - prevTime)

      unit.PhysicsLastTime = curTime
      unit.PhysicsLastPosition = position

      if unit.bPreventDI and not unit:HasModifier("modifier_rooted") then
        unit:AddNewModifier(unit, nil, "modifier_rooted", {})
      end

      if unit.bSlide and unit.nSkipSlide <= 0 then
        slideVelocity = ((position - prevPosition) - lastVelocity + unit.vSlideVelocity) * unit.fSlideMultiplier
      else
        --print(unit.nSkipSlide)
        unit.vSlideVelocity = Vector(0,0,0)
      end

      unit.nSkipSlide = unit.nSkipSlide - 1

      -- Adjust velocity
      local newVelocity = unit.vVelocity + unit.vAcceleration + (-1 * unit.fFriction * unit.vVelocity) + slideVelocity
      local newVelLength
      if unit.fFlatFriction > 0 then
        newVelLength = newVelocity:Length()
        if newVelLength ~= 0 then
          newVelocity = newVelocity * (math.max(0, newVelLength - unit.fFlatFriction) / newVelLength)
        end
      end

      local staticSum = unit.staticSum
      newVelocity = newVelocity + staticSum
      --local staticSumLength = staticSum:Length()

      local vel = unit.vVelocity + staticSum
      --local staticSumz = staticSum.z
      --local newVelz = newVelocity.z
      local dontSet = false
      local dontSetGround = false

      -- Calculate new position
      local newPos = position + vel

      local blockedPos = not GridNav:IsTraversable(position) or GridNav:IsBlocked(position)
      if not blockedPos then
        unit.vLastGoodPosition = position
        unit.nStuckFrames = 0
      else
        unit.nStuckFrames = unit.nStuckFrames + 1
      end

      if vel ~= Vector(0,0,0) or slideVelocity ~= Vector(0,0,0) or unit.nNavCollision == PHYSICS_NAV_GROUND then
        if unit.nNavCollision == PHYSICS_NAV_GROUND then
          local newGround = GetGroundPosition(newPos, unit)
          local ground = GetGroundPosition(position, unit)

          --if unit.vVelocity.x ~= 0 and unit.vVelocity.y ~= 0 then
          if newPos.z - newGround.z < 0 or position.z - ground.z < 0 then -- and newPos.z ~= position.z then
            local velLen = Vector(vel.x,vel.y,0):Length()
            local diff = vel:Normalized()
            local subpos = position
            local minnormal = Vector(0,0,1)
            --local avgnormal = Vector(0,0,0)
            for i=1,math.ceil(velLen)+1 do
              local normal = Physics:CalcNormal(subpos, unit, 15)
              --local subground = GetGroundPosition(subpos, unit)
              --print(i .. ' -- ' .. tostring(normal))
              if normal.z < minnormal.z then
                minnormal = normal
                --subground = subpos
              end
              --DebugDrawLine_vCol(subground, subground + normal * 100, Vector(100,0,0), true, 1.1)
              subpos = subpos + diff
              --avgnormal = avgnormal + normal
            end

            if minnormal.z < unit.fNavGroundAngle then
              --steep
              local xynorm = Vector(minnormal.x, minnormal.y, 0)
              local xynormlen = xynorm:Length()
              if xynorm:Length() > .98 then
                minnormal = xynorm / xynormlen
                --avgnormal = Vector(avgnormal.x, avgnormal.y, 0):Normalized()
              end

              --local velz = vel.z
              --newVelocity.z = 0
              --vel.z = 0

              local dot = vel:Dot(-1 * minnormal) *1.01
              if dot >= 0 then
                vel = vel + dot * minnormal
                newVelocity = newVelocity + newVelocity:Dot(-1 * minnormal)*1.01 * minnormal
                staticSum = staticSum + staticSum:Dot(-1 * minnormal)*1.01 * minnormal
              end

              newPos = position + vel
              --local nz = newPos.z
              --DebugDrawCircle(newPos, Vector(0,255,0), 1, 15, true, 1.1)
              local gnorm = GetGroundPosition(newPos + minnormal * 50, unit)
              --DebugDrawCircle(gnorm, Vector(255,0,0), 1, 15, true, 1.1)
              --DebugDrawCircle(unit.lastGoodGround, Vector(255,255,255), 1, 15, true, 1.1)
              local ng = GetGroundPosition(newPos, unit)
              if ng.z >= newPos.z and newPos.z < gnorm.z then
                --print(tostring(newPos.z) .. ' -- ' .. tostring(gnorm.z) .. ' -- ' .. tostring(ng.z) .. ' -- ' .. tostring(unit.lastGoodGround.z))
                if ng.z > gnorm.z then
                  newPos.z = gnorm.z
                else
                  newPos.z = ng.z
                end
                staticSum.z = 0
                if newPos.z > position.z and (newPos - position):Normalized().z > unit.fNavGroundAngle then --newPos.z-position.z > vel.z*1.5 then
                  --newPos = Vector(position.x,position.y,unit.lastGoodGround.z)
                  newPos = position + Vector(0,0,newVelocity.z)
                  if newPos.z < unit.lastGoodGround.z then
                    newPos.z = unit.lastGoodGround.z
                    newVelocity.z = math.max(0, newVelocity.z)
                  end
                else
                  newVelocity.z = math.max(0, newVelocity.z)
                end
              end

              unit:SetAbsOrigin(newPos)
              dontSet = true
              dontSetGround = true
              ground = ng
            end
          else
            unit.lastGoodGround = ground
          end

          local bound = 1
          if unit.fBoundOverride then
            bound = unit.fBoundOverride
          elseif unit.GetPaddedCollisionRadius then
            bound = unit:GetPaddedCollisionRadius()
          elseif unit.GetBoundingMaxs then
            bound = math.max(unit:GetBoundingMaxs().x, unit:GetBoundingMaxs().y)
          end
          -- tree check
          local connect = position-- + diff * bound
          local treeConnect = (not GridNav:IsTraversable(connect) or GridNav:IsBlocked(connect)) and GridNav:IsNearbyTree(connect, 30, true)
          local lookaheadNum = unit.nNavGridLookahead
          if unit.bAdaptiveNavGridLookahead then
            lookaheadNum = math.ceil(vel:Length() / 16)
          end
          local diff = vel:Normalized()
          local tot = lookaheadNum + 1
          local div = 1 / tot
          local index = 1
          while not treeConnect and index < tot do
            connect = position + vel * (div * index) + diff * bound
            treeConnect = (not GridNav:IsTraversable(connect) or GridNav:IsBlocked(connect)) and GridNav:IsNearbyTree(connect, 30, true)
            if treeConnect then
              DebugDrawCircle(connect, Vector(0,200,0), 100, 10, true, 1)
            end
            index = index + 1
          end

          --print (tostring(treeConnect) .. ' -- ' .. ground.z .. ' -- ' .. newPos.z .. ' -- ' .. position.z)
          if treeConnect and ground.z + 340 >= newPos.z and newPos.z + 2 > ground.z then
            if position.z >= ground.z + 340 then
              newVelocity.z = math.max(0, newVelocity.z)
              staticSum.z = math.max(0, staticSum.z)
              --unit:SetAbsOrigin(newPos + Vector(0,0,ground.z + 340 - newPos.z))
              newPos = Vector(newPos.x, newPos.y, ground.z + 340)
              --print('treetop')
            else
              --print('treeConnect')
              local vec = Vector(GridNav:GridPosToWorldCenterX(GridNav:WorldToGridPosX(connect.x)), GridNav:GridPosToWorldCenterY(GridNav:WorldToGridPosY(connect.y)), ground.z)
              --DebugDrawCircle(vec, Vector(200,200,200), 100, 10, true, .5)
              if unit.bCutTrees then
                local ents = Entities:FindAllByClassnameWithin("ent_dota_tree", vec, 70)
                if #ents > 0 then
                  local tree = ents[1]
                  tree:CutDown(unit:GetTeamNumber())
                end
              else
                local off = (Vector(position.x,position.y,vec.z) - vec):Normalized()
                local normal
                if math.abs(off.x) > math.abs(off.y) then
                  normal = Vector(math.abs(off.x)/off.x, 0, 0)
                  local vec2 = vec + normal * 64
                  local treeConnect2 = (not GridNav:IsTraversable(vec2) or GridNav:IsBlocked(vec2)) and GridNav:IsNearbyTree(vec2, 30, true)
                  if treeConnect2 then
                    normal = Vector(0, math.abs(off.y)/off.y, 0)
                    vec2 = vec + normal * 64
                    treeConnect2 = (not GridNav:IsTraversable(vec2) or GridNav:IsBlocked(vec2)) and GridNav:IsNearbyTree(vec2, 30, true)
                    if treeConnect2 then
                      normal = (Vector(diff.x,diff.y,0) * -1):Normalized()
                    end
                  end
                else
                  normal = Vector(0, math.abs(off.y)/off.y, 0)
                  local vec2 = vec + normal * 64
                  local treeConnect2 = (not GridNav:IsTraversable(vec2) or GridNav:IsBlocked(vec2)) and GridNav:IsNearbyTree(vec2, 30, true)
                  if treeConnect2 then
                    normal = Vector(math.abs(off.x)/off.x, 0, 0)
                    vec2 = vec + normal * 64
                    treeConnect2 = (not GridNav:IsTraversable(vec2) or GridNav:IsBlocked(vec2)) and GridNav:IsNearbyTree(vec2, 30, true)
                    if treeConnect2 then
                      normal = (Vector(diff.x,diff.y,0) * -1):Normalized()
                    end
                  end
                end

                local dot = vel:Dot(-1 * normal)
                if dot >= 0 then
                  vel = vel + dot * 1.0 * normal
                  newVelocity = newVelocity + newVelocity:Dot(-1 * normal) * 1.0 * normal
                  staticSum = staticSum + staticSum:Dot(-1 * normal) * 1.0 * normal
                  local newground = GetGroundPosition(position + vel, unit)
                  local new = position + vel
                  if newground.z > new.z then
                    new.z = newground.z
                  end

                  off = (Vector(new.x, new.y, vec.z) - vec):Normalized()
                  local scalar = math.min((32+bound) / math.abs(off.x), (32+bound) / math.abs(off.y))
                  --local scalar = math.min((32) / math.abs(off.x), (32) / math.abs(off.y))
                  unit.nSkipSlide = 1
                  newPos = vec + Vector(scalar*off.x, scalar*off.y, new.z - vec.z)
                end
                --unit:SetAbsOrigin(new)
              end
            end
          end
        elseif unit.bFollowNavMesh then
          local diff = vel:Normalized()

          local bound = 1
          if unit.fBoundOverride then
            bound = unit.fBoundOverride
          elseif unit.GetPaddedCollisionRadius then
            bound = unit:GetPaddedCollisionRadius() + 1
          elseif unit.GetBoundingMaxs then
            bound = math.max(unit:GetBoundingMaxs().x, unit:GetBoundingMaxs().y)
          end

          local connect = position-- + diff * bound
          local navConnect = not GridNav:IsTraversable(connect) or GridNav:IsBlocked(connect)
          local lookaheadNum = unit.nNavGridLookahead
          if unit.bAdaptiveNavGridLookahead then
            lookaheadNum = math.ceil(unit.vVelocity:Length() / 32)
          end
          local tot = lookaheadNum + 1
          local div = 1 / tot
          local index = 1
          while not navConnect and index < tot do
            connect = position + unit.vVelocity * (div * index) + diff * bound
            navConnect = not GridNav:IsTraversable(connect) or GridNav:IsBlocked(connect)
            index = index + 1
          end
          if unit.nNavCollision == PHYSICS_NAV_HALT and navConnect then
            newVelocity = Vector(0,0,0)
            staticSum = Vector(0,0,0)
            FindClearSpaceForUnit(unit, newPos, true)
            dontSet = true
            unit.nSkipSlide = 1
          elseif unit.nNavCollision == PHYSICS_NAV_SLIDE and navConnect then
            local navX = GridNav:WorldToGridPosX(connect.x)
            local navY = GridNav:WorldToGridPosY(connect.y)
            local navPos = Vector(GridNav:GridPosToWorldCenterX(navX), GridNav:GridPosToWorldCenterY(navY), 0)
            --unit.nRebounceFrames = unit.nMaxRebounce

            local normal = nil
            local anggrid = self.anggrid
            local offX = self.offsetX
            local offY = self.offsetY
            if anggrid then
              --local angSize = #anggrid
              local angX = navX + offX
              local angY = navY + offY

              local angle = anggrid[angX][angY]
              if angle ~= -1 then
                angle = angle
                normal = -1 * RotatePosition(Vector(0,0,0), QAngle(0,angle,0), Vector(1,0,0))
              end
            end

            local dir = navPos - position
            if normal == nil then
              dir.z = 0
              dir = dir:Normalized()
              if dir:Dot(Vector(1,0,0)) > .707 then
                normal = Vector(1,0,0)
                local navPos2 = navPos + Vector(-64,0,0)
                local navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                if navConnect2 then
                  if vel.y > 0 then
                    normal = Vector(0,1,0)
                    navPos2 = navPos + Vector(0,-64,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x, diff.y, diff.z)
                    end
                  else
                    normal = Vector(0,-1,0)
                    navPos2 = navPos + Vector(0,64,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x, diff.y, diff.z)
                    end
                  end
                end
              elseif dir:Dot(Vector(-1,0,0)) > .707 then
                normal = Vector(-1,0,0)
                local navPos2 = navPos + Vector(64,0,0)
                local navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                if navConnect2 then
                  if vel.y > 0 then
                    normal = Vector(0,1,0)
                    navPos2 = navPos + Vector(0,-64,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x, diff.y, diff.z)
                    end
                  else
                    normal = Vector(0,-1,0)
                    navPos2 = navPos + Vector(0,64,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x, diff.y, diff.z)
                    end
                  end
                end
              elseif dir:Dot(Vector(0,1,0)) > .707 then
                normal = Vector(0,1,0)
                local navPos2 = navPos + Vector(0,-64,0)
                local navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                if navConnect2 then
                  if vel.x > 0 then
                    normal = Vector(1,0,0)
                    navPos2 = navPos + Vector(-64,0,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x, diff.y, diff.z)
                    end
                  else
                    normal = Vector(-1,0,0)
                    navPos2 = navPos + Vector(64,0,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x, diff.y, diff.z)
                    end
                  end
                end
              elseif dir:Dot(Vector(0,-1,0)) > .707 then
                normal = Vector(0,-1,0)
                local navPos2 = navPos + Vector(0,64,0)
                local navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                if navConnect2 then
                  if vel.x > 0 then
                    normal = Vector(-1,0,0)
                    navPos2 = navPos + Vector(-64,0,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x, diff.y, diff.z)
                    end
                  else
                    normal = Vector(0,-1,0)
                    navPos2 = navPos + Vector(64,0,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x, diff.y, diff.z)
                    end
                  end
                end
              end
            end

            if unit.PhysicsOnPreSlide then
              local status, nextCall = pcall(unit.PhysicsOnPreSlide, unit, normal)
              if not status then
                print('[PHYSICS] Failed OnPreSlide: ' .. nextCall)
              end
            end

            newVelocity = (-1 * newVelocity:Dot(normal) * normal) + newVelocity
            staticSum = (-1 * staticSum:Dot(normal) * normal) + staticSum
            local ndir = dir * -1
            local scalar = math.min((32+bound) / math.abs(ndir.x), (32+bound) / math.abs(ndir.y))

            unit.nSkipSlide = 1
            newPos = navPos + Vector(scalar*ndir.x, scalar*ndir.y, newPos.z)

            if unit.PhysicsOnSlide then
              local status, nextCall = pcall(unit.PhysicsOnSlide, unit, normal)
              if not status then
                print('[PHYSICS] Failed OnSlide: ' .. nextCall)
              end
            end
          elseif unit.nRebounceFrames <= 0 and unit.nNavCollision == PHYSICS_NAV_BOUNCE and navConnect then
            local navX = GridNav:WorldToGridPosX(connect.x)
            local navY = GridNav:WorldToGridPosY(connect.y)
            local navPos = Vector(GridNav:GridPosToWorldCenterX(navX), GridNav:GridPosToWorldCenterY(navY), 0)
            unit.nRebounceFrames = unit.nMaxRebounce

            local normal = nil
            local anggrid = self.anggrid
            local offX = self.offsetX
            local offY = self.offsetY
            if anggrid then
              --local angSize = #anggrid
              local angX = navX + offX
              local angY = navY + offY

              local angle = anggrid[angX][angY]
              if angle ~= -1 then
                angle = angle
                normal = RotatePosition(Vector(0,0,0), QAngle(0,angle,0), Vector(1,0,0))
              end
            end

            if normal == nil then
              local dir = navPos - position
              dir.z = 0
              dir = dir:Normalized()
              if dir:Dot(Vector(1,0,0)) > .707 then
                normal = Vector(1,0,0)
                local navPos2 = navPos + Vector(-64,0,0)
                local navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                if navConnect2 then
                  if vel.y > 0 then
                    normal = Vector(0,1,0)
                    navPos2 = navPos + Vector(0,-64,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x * -1, diff.y * -1, diff.z)
                    end
                  else
                    normal = Vector(0,-1,0)
                    navPos2 = navPos + Vector(0,64,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x * -1, diff.y * -1, diff.z)
                    end
                  end
                end
              elseif dir:Dot(Vector(-1,0,0)) > .707 then
                normal = Vector(-1,0,0)
                local navPos2 = navPos + Vector(64,0,0)
                local navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                if navConnect2 then
                  if vel.y > 0 then
                    normal = Vector(0,1,0)
                    navPos2 = navPos + Vector(0,-64,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x * -1, diff.y * -1, diff.z)
                    end
                  else
                    normal = Vector(0,-1,0)
                    navPos2 = navPos + Vector(0,64,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x * -1, diff.y * -1, diff.z)
                    end
                  end
                end
              elseif dir:Dot(Vector(0,1,0)) > .707 then
                normal = Vector(0,1,0)
                local navPos2 = navPos + Vector(0,-64,0)
                local navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                if navConnect2 then
                  if vel.x > 0 then
                    normal = Vector(1,0,0)
                    navPos2 = navPos + Vector(-64,0,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x * -1, diff.y * -1, diff.z)
                    end
                  else
                    normal = Vector(-1,0,0)
                    navPos2 = navPos + Vector(64,0,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x * -1, diff.y * -1, diff.z)
                    end
                  end
                end
              elseif dir:Dot(Vector(0,-1,0)) > .707 then
                normal = Vector(0,-1,0)
                local navPos2 = navPos + Vector(0,64,0)
                local navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                if navConnect2 then
                  if vel.x > 0 then
                    normal = Vector(-1,0,0)
                    navPos2 = navPos + Vector(-64,0,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x * -1, diff.y * -1, diff.z)
                    end
                  else
                    normal = Vector(0,-1,0)
                    navPos2 = navPos + Vector(64,0,0)
                    navConnect2 = not GridNav:IsTraversable(navPos2) or GridNav:IsBlocked(navPos2)
                    if navConnect2 then
                      normal = Vector(diff.x * -1, diff.y * -1, diff.z)
                    end
                  end
                end
              end
            end

            if unit.PhysicsOnPreBounce then
              local status, nextCall = pcall(unit.PhysicsOnPreBounce, unit, normal)
              if not status then
                print('[PHYSICS] Failed OnPreBounce: ' .. nextCall)
              end
            end
            newVelocity = ((-2 * newVelocity:Dot(normal) * normal) + newVelocity) * unit.fBounceMultiplier
            staticSum = ((-2 * staticSum:Dot(normal) * normal) + staticSum) * unit.fBounceMultiplier
            if unit.PhysicsOnBounce then
              local status, nextCall = pcall(unit.PhysicsOnBounce, unit, normal)
              if not status then
                print('[PHYSICS] Failed OnBounce: ' .. nextCall)
              end
            end
          end
        end
      end

      --if newPos.z > unit:GetAbsOrigin().z then print (tostring(newPos) .. ' -- ' .. tostring(unit:GetAbsOrigin())) end
      --if newPos == unit:GetAbsOrigin() and newPos ~= prevPosition then print (tostring(dontSet) .. ' -- ' .. tostring(newPos) .. ' -- ' .. tostring(unit:GetAbsOrigin())) end
      newVelLength = newVelocity:Length()
      local groundPos = GetGroundPosition(newPos, unit)

      if unit.nVelocityMax > 0 and newVelLength > unit.nVelocityMax then
        newVelocity = newVelocity:Normalized() * unit.nVelocityMax
        staticSum = staticSum:Normalized() * unit.nVelocityMax
      end

      local xylen = newVelocity:Length2D()
      if unit.vAcceleration.x == 0 and unit.vAcceleration.y == 0 and xylen < unit.fVelocityClamp and (unit.vAcceleration.z == 0 or groundPos.z == newPos.z) then
        --print('clamp')
        newVelocity = Vector(0,0,newVelocity.z)
        staticSum = Vector(0,0,staticSum.z)

        if unit.bHibernate then
          unit:DoHibernate()
          local ent = Entities:FindInSphere(nil, position, 35)
          local blocked = false
          while ent ~= nil and not blocked do
            if ent.GetUnitName ~= nil and ent ~= unit then
              blocked = true
            end
            --print(ent:GetClassname() .. " -- " .. ent:GetName() .. " -- " .. tostring(ent.IsHero))
            ent = Entities:FindInSphere(ent, position, 35)
          end
          if blocked or blockedPos or GridNav:IsNearbyTree(position, 30, true) then
            FindClearSpaceForUnit(unit, position, true)
            unit.nSkipSlide = 1
            --print('FCS hib')
          end
          if unit.PhysicsHibernateCallback ~= nil then
            local status, nextCall = pcall(unit.PhysicsHibernateCallback, unit)
            if not status then
              print('[PHYSICS] Failed HibernateCallback: ' .. nextCall)
            end
          end
          return
        end

        --[[if unit:HasModifier("modifier_rooted") then
          unit:RemoveModifierByName("modifier_rooted")
        end

        local ent = Entities:FindInSphere(nil, position, 35)
        local blocked = false
        while ent ~= nil and not blocked do
          if ent.IsHero ~= nil and ent ~= unit then
            blocked = true
          end
          --print(ent:GetClassname() .. " -- " .. ent:GetName() .. " -- " .. tostring(ent.IsHero))
          ent = Entities:FindInSphere(ent, position, 35)
        end
        if blocked or not GridNav:IsTraversable(position) or GridNav:IsBlocked(position) or GridNav:IsNearbyTree(position, 30, true) then
          FindClearSpaceForUnit(unit, position, true)
          unit.nSkipSlide = 1
          --print('FCS nothib lowv + blocked')
        end ]]
      end

      if not dontSetGround then
        if unit.nLockToGround == PHYSICS_GROUND_LOCK then
          groundPos = GetGroundPosition(newPos, unit)
          newPos = groundPos
          newVelocity.z = 0
          staticSum.z = 0
        elseif unit.nLockToGround == PHYSICS_GROUND_ABOVE then
          groundPos = GetGroundPosition(newPos, unit)
          --print(groundPos.z .. ' -- ' .. newPos.z .. ' -- ' .. (groundPos - position):Normalized().z)
          if unit.nNavCollision == PHYSICS_NAV_GROUND and groundPos.z > position.z and (groundPos - position):Normalized().z > unit.fNavGroundAngle then
            newVelocity.z = math.max(0, newVelocity.z)
            staticSum.z = 0
            --[[newPos = position + Vector(0,0,newVelocity.z)
            if newPos.z < unit.lastGoodGround.z then
              DebugDrawCircle(unit.lastGoodGround, Vector(255,255,255), 1, 15, true, 1.1)
              DebugDrawCircle(groundPos, Vector(255,0,0), 1, 15, true, 1.1)
              DebugDrawCircle(newPos, Vector(0,255,0), 1, 15, true, 1.1)
              print ('LAST GROUND2')
              newPos.z = unit.lastGoodGround.z
              newVelocity.z = 0
              staticSum.z = 0
            end]]
          elseif groundPos.z >= newPos.z then
            newPos = groundPos
            newVelocity.z = 0
            staticSum.z = 0
          end
        end
      end

      if not dontSet then
        unit:SetAbsOrigin(newPos)
      end

      unit.nRebounceFrames = unit.nRebounceFrames - 1
      unit.vLastVelocity = unit.vVelocity
      unit.vVelocity = newVelocity - staticSum

      if unit.PhysicsFrameCallback ~= nil then
        local status, nextCall = pcall(unit.PhysicsFrameCallback, unit)
        if not status then
          print('[PHYSICS] Failed FrameCallback: ' .. nextCall)
        end
      end

      if unit.nNavCollision ~= PHYSICS_NAV_NOTHING and  unit.bAutoUnstuck and unit.nStuckFrames >= unit.nStuckTimeout then
        unit.nStuckFrames = 0
        unit.nSkipSlide = 1

        local navX = GridNav:WorldToGridPosX(position.x)
        local navY = GridNav:WorldToGridPosY(position.y)

        local anggrid = self.anggrid
        local offX = self.offsetX
        local offY = self.offsetY
        if anggrid then
          --local angSize = #anggrid
          local angX = navX + offX
          local angY = navY + offY

          local angle = anggrid[angX][angY]
          if angle ~= -1 then
            local normal = RotatePosition(Vector(0,0,0), QAngle(0,angle,0), Vector(1,0,0))
            unit:SetAbsOrigin(position + normal * 64)
          else
            unit:SetAbsOrigin(unit.vLastGoodPosition)
          end
        else
          unit:SetAbsOrigin(unit.vLastGoodPosition)
        end
      end

      return curTime
    end
  })

  unit.PhysicsTimer = Physics.timers[unit.PhysicsTimerName]
  unit.vVelocity = Vector(0,0,0)
  unit.vLastVelocity = Vector(0,0,0)
  unit.vAcceleration = Vector(0,0,0)
  unit.fFriction = .05
  unit.fFlatFriction = 0
  unit.PhysicsLastPosition = unit:GetAbsOrigin()
  unit.PhysicsLastTime = GameRules:GetGameTime()
  unit.vTotalVelocity = Vector(0,0,0)
  unit.bFollowNavMesh = true
  unit.nLockToGround = PHYSICS_GROUND_ABOVE
  unit.bPreventDI = false
  unit.bSlide = false
  unit.nNavCollision = PHYSICS_NAV_SLIDE
  unit.fNavGroundAngle = .6
  unit.fSlideMultiplier = 0.1
  unit.nVelocityMax = 0
  unit.PhysicsFrameCallback = nil
  unit.fVelocityClamp = 20.0 / 30.0
  unit.bHibernate = true
  unit.bHibernating = false
  unit.bStarted = true
  unit.bCutTrees = false
  unit.vSlideVelocity = Vector(0,0,0)
  unit.nNavGridLookahead = 1
  unit.bAdaptiveNavGridLookahead = false
  unit.nSkipSlide = 0
  unit.nMaxRebounce = 2
  unit.nRebounceFrames = 2
  unit.vLastGoodPosition = unit:GetAbsOrigin()
  unit.bAutoUnstuck = true
  unit.nStuckTimeout = 600
  unit.nStuckFrames = 0
  unit.fBounceMultiplier = 1.0
  unit.oColliders = {}
  unit.fMass = 100
  unit.staticForces = {}
  unit.staticSum = Vector(0,0,0)
end

function Physics:BlockInSphere(unit, unitToRepel, radius, findClearSpace)
  local pos = unit:GetAbsOrigin()
  local vPos = unitToRepel:GetAbsOrigin()
  local dir = vPos - pos
  local dist2 = VectorDistanceSq(pos, vPos)
  local move = radius
  local move2 = move * move

  if move2 < dist2 then
    return
  end

  if IsPhysicsUnit(unitToRepel) then
    unitToRepel.nSkipSlide = 1
  end

  if findClearSpace then
    FindClearSpaceForUnit(unitToRepel, pos + (dir:Normalized() * move), true)
  else
    unitToRepel:SetAbsOrigin(pos + (dir:Normalized() * move))
  end
end

function Physics:BlockInBox(unit, dist, normal, buffer, findClearSpace)
  local toside = (dist + buffer) * normal

  if IsPhysicsUnit(unit) then
    unit.nSkipSlide = 1
  end

  if findClearSpace then
    FindClearSpaceForUnit(unit, unit:GetAbsOrigin() + toside, true)
  else
    unit:SetAbsOrigin(unit:GetAbsOrigin() + toside)
  end
end

function Physics:BlockInAABox(unit, xblock, value, buffer, findClearSpace)
  if IsPhysicsUnit(unit) then
    unit.nSkipSlide = 1
  end

  local pos = unit:GetAbsOrigin()

  if xblock then
    pos.x = value
  else
    pos.y = value
  end

  if findClearSpace then
    FindClearSpaceForUnit(unit, pos, true)
  else
    unit:SetAbsOrigin(pos)
  end
end

function Physics:DistanceToLine(point, lineA, lineB)
  local a = (lineA - point):Length()
  local b = (lineB - point):Length()
  local c = (lineB - lineA):Length()
  local s = (a+b+c)/2
  local num = (math.sqrt(s*(s-a)*(s-b)*(s-c)) * 2 / c)
  if num ~= num then
    return 0
  end
  return num
end

function Physics:CreateBox(a, b, width, center)
  local az = Vector(a.x,a.y,0)
  local bz = Vector(b.x,b.y,0)
  local height = math.abs(b.z - a.z)
  if height < 1 then
    b.z = b.z + width / 2
    a.z = a.z - width / 2
  end

  local dir = (bz-az):Normalized()
  local rot = Vector(-1*dir.y,dir.x,0)

  local box = {}
  if center then
    box[1] = a + -1 * rot * width / 2
    box[2] = b + -1 * rot * width / 2
    box[3] = a + rot * width / 2
  else
    box[1] = a
    box[2] = b
    box[3] = a + rot * width
  end

  return box
end

function Physics:PrecalculateBoxDraw(box)
  local ang = RotationDelta(VectorToAngles(box.upNormal), VectorToAngles(Vector(1,0,0))).y
  local ang2 = RotationDelta(VectorToAngles(box.rightNormal), VectorToAngles(Vector(1,0,0))).y
  if ang > 90 then
    ang = 180 - ang
  elseif ang < -90 then
    ang = -180 - ang
  end

  if ang2 > 90 then
    ang2 = 180 - ang2
  elseif ang2 < -90 then
    ang2 = -180 - ang2
  end

  local a = ang
  if math.abs(ang2) < math.abs(ang) then
    a = ang2
  end

  local aRot = RotatePosition(box.a, QAngle(0, a, 0), box.a)
  local bRot = RotatePosition(box.a, QAngle(0, a, 0), box.b)
  local cRot = RotatePosition(box.a, QAngle(0, a, 0), box.c)
  local dRot = RotatePosition(box.a, QAngle(0, a, 0), box.d)

  local minX = math.min(math.min(math.min(aRot.x, bRot.x), cRot.x), dRot.x)
  local minY = math.min(math.min(math.min(aRot.y, bRot.y), cRot.y), dRot.y)
  local maxX = math.max(math.max(math.max(aRot.x, bRot.x), cRot.x), dRot.x)
  local maxY = math.max(math.max(math.max(aRot.y, bRot.y), cRot.y), dRot.y)

  box.drawAngle = -1 * a
  box.drawMins = Vector(minX, minY, box.zMin)
  box.drawMaxs = Vector(maxX, maxY, box.zMax)
end

function Physics:PrecalculateBox(box)
  box.zMin = math.min(math.min(box[1].z, box[2].z), box[3].z)
  box.zMax = math.max(math.max(box[1].z, box[2].z), box[3].z)
  box.center = box[2] + (box[3] - box[2]) / 2
  box.center.z = (box.zMin + box.zMax) / 2
  box.radius = math.max((box[3] - box.center):Length(), (box[2] - box.center):Length())
  box.middle = Vector(box.center.x, box.center.y, box.center.z)
  box.middle.z = 0
  box.a = box[1]
  box.a.z = 0
  box.b = box[2]
  box.b.z = 0
  box.d = box[3]
  box.d.z = 0
  box.c = box.b + (box.d - box.a)
  box.upNormal = (box.d - box.a):Normalized()
  box.rightNormal = (box.b - box.a):Normalized()

  box[1] = nil
  box[2] = nil
  box[3] = nil

  box.ab = box.b - box.a
  box.ad = box.d - box.a
  box.ab2 = box.ab:Dot(box.ab)
  box.ad2 = box.ad:Dot(box.ad)

  box.recalculate = nil
  return box
end

function Physics:PrecalculateAABox(box)
  box.xMin = math.min(box[1].x, box[2].x)
  box.xMax = math.max(box[1].x, box[2].x)
  box.yMin = math.min(box[1].y, box[2].y)
  box.yMax = math.max(box[1].y, box[2].y)
  box.zMin = math.min(box[1].z, box[2].z)
  box.zMax = math.max(box[1].z, box[2].z)
  box.center = Vector((box.xMin + box.xMax) / 2, (box.yMin + box.yMax) / 2, (box.zMin + box.zMax) / 2)
  box.radius =(Vector(box.xMax, box.yMax, box.zMax) - box.center):Length()
  box.middle = Vector(box.center.x, box.center.y, 0)

  box.xScale = box.xMax - box.middle.x
  box.yScale = box.yMax - box.middle.y

  box[1] = nil
  box[2] = nil

  box.recalculate = nil
  return box
end

if not Physics.timers then Physics:start() end

-- Physics:CreateColliderProfile("blocker",
  -- {
    -- type = COLLIDER_SPHERE,
    -- radius = 100,
    -- recollideTime = 0,
    -- skipFrames = 0,
    -- moveSelf = false,
    -- buffer = 0,
    -- findClearSpace = false,
    -- test = function(self, collider, collided)
      -- return collided.IsRealHero and collided:IsRealHero() and collider:GetTeam() ~= collided:GetTeam()
    -- end,
    -- action = function(self, unit, v)
      -- if self.moveSelf then
        -- Physics:BlockInSphere(v, unit, self.radius + self.buffer, self.findClearSpace)
      -- else
        -- Physics:BlockInSphere(unit, v, self.radius + self.buffer, self.findClearSpace)
      -- end
    -- end
  -- })

-- Physics:CreateColliderProfile("delete",
  -- {
    -- type = COLLIDER_SPHERE,
    -- radius = 100,
    -- recollideTime = 0,
    -- skipFrames = 0,
    -- deleteSelf = true,
    -- removeCollider = true,
    -- test = function(self, collider, collided)
      -- return collided.IsRealHero and collided:IsRealHero() and collider:GetTeam() ~= collided:GetTeam()
    -- end,
    -- action = function(self, unit, v)
      -- if self.deleteSelf then
        -- UTIL_Remove(unit)
      -- else
        -- UTIL_Remove(v)
      -- end

      -- if self.removeCollider then
        -- Physics:RemoveCollider(self)
      -- end
    -- end
  -- })

-- Physics:CreateColliderProfile("gravity",
  -- {
    -- type = COLLIDER_SPHERE,
    -- radius = 100,
    -- recollideTime = 0,
    -- skipFrames = 0,
    -- minRadius = 0,
    -- fullRadius = 0,
    -- linear = false,
    -- force = 1000,
    -- test = function(self, collider, collided)
      -- return collided.IsRealHero and collided:IsRealHero() and collider:GetTeam() ~= collided:GetTeam() and IsPhysicsUnit(collided)
    -- end,
    -- action = function(self, unit, v)
      -- local pos = unit:GetAbsOrigin()
      -- local vPos = v:GetAbsOrigin()
      -- local dir = pos - vPos
      -- local len = dir:Length()
      -- if len > self.minRadius then
        -- local radDiff = self.radius - self.fullRadius
        -- local dist = math.max(0, len - self.fullRadius)
        -- local factor = (radDiff - dist) / radDiff

        -- local force = self.force
        -- if self.linear then
          -- force = force * factor / 30
        -- else
          -- local factor2 = factor * factor
          -- force = force * factor2 / 30
        -- end

        -- force = force * (self.skipFrames + 1)

        -- v:AddPhysicsVelocity(dir:Normalized() * force)
      -- end
    -- end
  -- })

-- Physics:CreateColliderProfile("repel",
  -- {
    -- type = COLLIDER_SPHERE,
    -- radius = 100,
    -- recollideTime = 0,
    -- skipFrames = 0,
    -- minRadius = 0,
    -- fullRadius = 0,
    -- linear = false,
    -- force = 1000,
    -- test = function(self, collider, collided)
      -- return collided.IsRealHero and collided:IsRealHero() and collider:GetTeam() ~= collided:GetTeam() and IsPhysicsUnit(collided)
    -- end,
    -- action = function(self, unit, v)
      -- local pos = unit:GetAbsOrigin()
      -- local vPos = v:GetAbsOrigin()
      -- local dir = pos - vPos
      -- local len = dir:Length()
      -- if len > self.minRadius then
        -- local radDiff = self.radius - self.fullRadius
        -- local dist = math.max(0, len - self.fullRadius)
        -- local factor = (radDiff - dist) / radDiff

        -- local force = self.force
        -- if self.linear then
          -- force = force * factor / 30
        -- else
          -- local factor2 = factor * factor
          -- force = force * factor2 / 30
        -- end

        -- force = force * (self.skipFrames + 1)

        -- v:AddPhysicsVelocity(-1 * dir:Normalized() * force)
      -- end
    -- end
  -- })

-- Physics:CreateColliderProfile("reflect",
  -- {
    -- type = COLLIDER_SPHERE,
    -- radius = 100,
    -- recollideTime = 0,
    -- skipFrames = 0,
    -- multiplier = 1,
    -- block = true,
    -- blockRadius = 100,
    -- moveSelf = false,
    -- findClearSpace = false,
    -- test = function(self, collider, collided)
      -- return collided.IsRealHero and collided:IsRealHero() and collider:GetTeam() ~= collided:GetTeam() and IsPhysicsUnit(collided)
    -- end,
    -- action = function(self, unit, v)
      -- local pos = unit:GetAbsOrigin()
      -- local vPos = v:GetAbsOrigin()
      -- local normal = vPos - pos
      -- normal = normal:Normalized()

      -- local newVelocity = v.vVelocity
      -- if newVelocity:Dot(normal) >= 0 then
        -- return
      -- end

      -- v:SetPhysicsVelocity(((-2 * newVelocity:Dot(normal) * normal) + newVelocity) * self.multiplier * 30)

      -- if self.block then
        -- if self.moveSelf then
          -- Physics:BlockInSphere(v, unit, self.blockRadius, self.findClearSpace)
        -- else
          -- Physics:BlockInSphere(unit, v, self.blockRadius, self.findClearSpace)
        -- end
      -- end
    -- end
  -- })

-- Physics:CreateColliderProfile("momentum",
  -- {
    -- type = COLLIDER_SPHERE,
    -- radius = 100,
    -- recollideTime = .1,
    -- skipFrames = 0,
    -- block = true,
    -- blockRadius = 50,
    -- moveSelf = false,
    -- findClearSpace = false,
    -- elasticity = 1,
    -- test = function(self, collider, collided)
      -- return collided.IsRealHero and collided:IsRealHero() and collider:GetTeam() ~= collided:GetTeam() and IsPhysicsUnit(collided)
    -- end,
    -- action = function(self, unit, v)
      -- if self.hitTime == nil or GameRules:GetGameTime() >= self.hitTime then
        -- local pos = unit:GetAbsOrigin()
        -- local vPos = v:GetAbsOrigin()
        -- local dir = vPos - pos
        -- local mass = unit:GetMass()
        -- local vMass = v:GetMass()
        -- --dir.z = 0
        -- dir = dir:Normalized()

        -- local neg = -1 * dir

        -- local dot = dir:Dot(unit:GetTotalVelocity())
        -- local dot2 = dir:Dot(v:GetTotalVelocity())

        -- local v1 = (self.elasticity * vMass * (dot2 - dot) + (mass * dot) + (vMass * dot2)) / (mass + vMass)
        -- local v2 = (self.elasticity * mass * (dot - dot2) + (mass * dot) + (vMass * dot2)) / (mass + vMass)

        -- --if dot < 1 and dot2 < 1 then
          -- --return
        -- --end

        -- unit:AddPhysicsVelocity((v1 - dot) * dir)
        -- v:AddPhysicsVelocity((v2 - dot2) * dir)

        -- if self.block then
          -- if self.moveSelf then
            -- Physics:BlockInSphere(v, unit, self.blockRadius, self.findClearSpace)
          -- else
            -- Physics:BlockInSphere(unit, v, self.blockRadius, self.findClearSpace)
          -- end
        -- end

        -- self.hitTime = GameRules:GetGameTime() + self.recollideTime
      -- end
    -- end
  -- })

-- Physics:CreateColliderProfile("momentumFull",
  -- {
    -- type = COLLIDER_SPHERE,
    -- radius = 100,
    -- recollideTime = .1,
    -- skipFrames = 0,
    -- block = true,
    -- blockRadius = 50,
    -- moveSelf = false,
    -- findClearSpace = false,
    -- elasticity = 1,
    -- test = function(self, collider, collided)
      -- return collided.IsRealHero and collided:IsRealHero() and collider:GetTeam() ~= collided:GetTeam() and IsPhysicsUnit(collided)
    -- end,
    -- action = function(self, unit, v)
      -- if self.hitTime == nil or GameRules:GetGameTime() >= self.hitTime then
        -- local pos = unit:GetAbsOrigin()
        -- local vPos = v:GetAbsOrigin()
        -- local dir = vPos - pos
        -- local mass = unit:GetMass()
        -- local vMass = v:GetMass()
        -- --dir.z = 0
        -- dir = dir:Normalized()

        -- local neg = -1 * dir

        -- local dot = unit:GetTotalVelocity():Length()
        -- local dot2 = -1 * v:GetTotalVelocity():Length()

        -- local v1 = (self.elasticity * vMass * (dot2 - dot) + (mass * dot) + (vMass * dot2)) / (mass + vMass)
        -- local v2 = (self.elasticity * mass * (dot - dot2) + (mass * dot) + (vMass * dot2)) / (mass + vMass)

        -- --if dot < 1 and dot2 < 1 then
          -- --return
        -- --end

        -- unit:AddPhysicsVelocity((v1 - dot) * dir)
        -- v:AddPhysicsVelocity((v2 - dot2) * dir)

        -- if self.block then
          -- if self.moveSelf then
            -- Physics:BlockInSphere(v, unit, self.blockRadius, self.findClearSpace)
          -- else
            -- Physics:BlockInSphere(unit, v, self.blockRadius, self.findClearSpace)
          -- end
        -- end

        -- self.hitTime = GameRules:GetGameTime() + self.recollideTime
      -- end
    -- end
  -- })

-- Physics:CreateColliderProfile("boxblocker",
  -- {
    -- type = COLLIDER_BOX,
    -- box = {Vector(0,0,0), Vector(200,100,500), Vector(0,100,0)},
    -- slide = true,
    -- recollideTime = 0,
    -- skipFrames = 0,
    -- buffer = 0,
    -- findClearSpace = false,
    -- test = function(self, unit)
      -- return unit.IsRealHero and unit:IsRealHero() and unit:GetTeam() ~= unit:GetTeam() and IsPhysicsUnit(unit)
    -- end,
    -- action = function(self, box, unit)
      -- --PrintTable(box)
      -- local pos = unit:GetAbsOrigin()
      -- pos.z = 0

      -- --face collide determination
      -- local diff =  (pos - box.middle):Normalized()
      -- local up = diff:Dot(box.upNormal)
      -- local right = diff:Dot(box.rightNormal)
      -- local normal = box.upNormal
      -- local toside = 0
      -- local leg1 = box.c
      -- local leg2 = box.d
      -- if up >= 0 then
        -- if right >= 0 then
          -- -- check top,right
          -- local u = Physics:DistanceToLine(pos, box.c, box.d)
          -- local r = Physics:DistanceToLine(pos, box.c, box.b)
          -- if u < r then
            -- normal = box.upNormal
            -- leg1 = box.c
            -- leg2 = box.d
            -- toside = u
          -- else
            -- normal = box.rightNormal
            -- leg1 = box.c
            -- leg2 = box.b
            -- toside = r
          -- end
        -- else
          -- -- check top,left
          -- local u = Physics:DistanceToLine(pos, box.c, box.d)
          -- local l = Physics:DistanceToLine(pos, box.a, box.d)
          -- if u < l then
            -- normal = box.upNormal
            -- leg1 = box.c
            -- leg2 = box.d
            -- toside = u
          -- else
            -- normal = -1 * box.rightNormal
            -- leg1 = box.a
            -- leg2 = box.d
            -- toside = l
          -- end
        -- end
      -- else
        -- if right >= 0 then
          -- -- check bot,right
          -- local b = Physics:DistanceToLine(pos, box.a, box.b)
          -- local r = Physics:DistanceToLine(pos, box.c, box.b)
          -- if b < r then
            -- normal = -1 * box.upNormal
            -- leg1 = box.a
            -- leg2 = box.b
            -- toside = b
          -- else
            -- normal = box.rightNormal
            -- leg1 = box.c
            -- leg2 = box.b
            -- toside = r
          -- end
        -- else
          -- -- check bot,left
          -- local b = Physics:DistanceToLine(pos, box.a, box.b)
          -- local l = Physics:DistanceToLine(pos, box.a, box.d)
          -- if b < l then
            -- normal = -1 * box.upNormal
            -- leg1 = box.c
            -- leg2 = box.d
            -- toside = b
          -- else
            -- normal = -1 * box.rightNormal
            -- leg1 = box.a
            -- leg2 = box.d
            -- toside = l
          -- end
        -- end
      -- end

      -- normal = normal:Normalized()

      -- Physics:BlockInBox(unit, toside, normal, self.buffer, self.findClearSpace)

      -- if self.slide and IsPhysicsUnit(unit) then
        -- unit:AddPhysicsVelocity(math.max(0,unit:GetPhysicsVelocity():Dot(normal * -1)) * normal)
      -- end
    -- end
  -- })

-- Physics:CreateColliderProfile("boxreflect",
  -- {
    -- type = COLLIDER_BOX,
    -- box = {Vector(0,0,0), Vector(200,100,500), Vector(0,100,0)},
    -- recollideTime = 0,
    -- skipFrames = 0,
    -- buffer = 0,
    -- block = true,
    -- findClearSpace = false,
    -- multiplier = 1,
    -- test = function(self, unit)
      -- return unit.IsRealHero and unit:IsRealHero() and unit:GetTeam() ~= unit:GetTeam() and IsPhysicsUnit(unit)
    -- end,
    -- action = function(self, box, unit)
      -- local pos = unit:GetAbsOrigin()
      -- pos.z = 0

      -- --face collide determination
      -- local diff =  (pos - box.middle):Normalized()
      -- local up = diff:Dot(box.upNormal)
      -- local right = diff:Dot(box.rightNormal)
      -- local normal = box.upNormal
      -- local toside = 0
      -- local leg1 = box.c
      -- local leg2 = box.d
      -- if up >= 0 then
        -- if right >= 0 then
          -- -- check top,right
          -- local u = Physics:DistanceToLine(pos, box.c, box.d)
          -- local r = Physics:DistanceToLine(pos, box.c, box.b)
          -- if u < r then
            -- normal = box.upNormal
            -- leg1 = box.c
            -- leg2 = box.d
            -- toside = u
          -- else
            -- normal = box.rightNormal
            -- leg1 = box.c
            -- leg2 = box.b
            -- toside = r
          -- end
        -- else
          -- -- check top,left
          -- local u = Physics:DistanceToLine(pos, box.c, box.d)
          -- local l = Physics:DistanceToLine(pos, box.a, box.d)
          -- if u < l then
            -- normal = box.upNormal
            -- leg1 = box.c
            -- leg2 = box.d
            -- toside = u
          -- else
            -- normal = -1 * box.rightNormal
            -- leg1 = box.a
            -- leg2 = box.d
            -- toside = l
          -- end
        -- end
      -- else
        -- if right >= 0 then
          -- -- check bot,right
          -- local b = Physics:DistanceToLine(pos, box.a, box.b)
          -- local r = Physics:DistanceToLine(pos, box.c, box.b)
          -- if b < r then
            -- normal = -1 * box.upNormal
            -- leg1 = box.a
            -- leg2 = box.b
            -- toside = b
          -- else
            -- normal = box.rightNormal
            -- leg1 = box.c
            -- leg2 = box.b
            -- toside = r
          -- end
        -- else
          -- -- check bot,left
          -- local b = Physics:DistanceToLine(pos, box.a, box.b)
          -- local l = Physics:DistanceToLine(pos, box.a, box.d)
          -- if b < l then
            -- normal = -1 * box.upNormal
            -- leg1 = box.c
            -- leg2 = box.d
            -- toside = b
          -- else
            -- normal = -1 * box.rightNormal
            -- leg1 = box.a
            -- leg2 = box.d
            -- toside = l
          -- end
        -- end
      -- end

      -- normal = normal:Normalized()

      -- if self.block then
        -- Physics:BlockInBox(unit, toside, normal, self.buffer, self.findClearSpace)
      -- end

      -- local newVelocity = unit.vVelocity
      -- if newVelocity:Dot(normal) >= 0 then
        -- return
      -- end

      -- unit:SetPhysicsVelocity(((-2 * newVelocity:Dot(normal) * normal) + newVelocity) * self.multiplier * 30)
    -- end
  -- })

-- Physics:CreateColliderProfile("aaboxblocker",
  -- {
    -- type = COLLIDER_AABOX,
    -- box = {Vector(0,0,0), Vector(200,100,500)},
    -- slide = true,
    -- recollideTime = 0,
    -- skipFrames = 0,
    -- buffer = 0,
    -- findClearSpace = false,
    -- test = function(self, unit)
      -- return unit.IsRealHero and unit:IsRealHero() and unit:GetTeam() ~= unit:GetTeam() and IsPhysicsUnit(unit)
    -- end,
    -- action = function(self, box, unit)
      -- --PrintTable(box)
      -- local pos = unit:GetAbsOrigin()
      -- pos.z = 0

      -- local x = pos.x
      -- local y = pos.y
      -- local middle = box.middle
      -- local xblock = true
      -- local value = 0
      -- local normal = Vector(1,0,0)

      -- if x > middle.x then
        -- if y > middle.y then
          -- -- up,right
          -- local relx = (pos.x - middle.x) / box.xScale
          -- local rely = (pos.y - middle.y) / box.yScale

          -- if relx > rely then
            -- --right
            -- normal = Vector(1,0,0)
            -- value = box.xMax
            -- xblock = true
          -- else
            -- --up
            -- normal = Vector(0,1,0)
            -- value = box.yMax
            -- xblock = false
          -- end
        -- elseif y <= middle.y then
          -- -- down,right
          -- local relx = (pos.x - middle.x) / box.xScale
          -- local rely = (middle.y - pos.y) / box.yScale

          -- if relx > rely then
            -- --right
            -- normal = Vector(1,0,0)
            -- value = box.xMax
            -- xblock = true
          -- else
            -- --down
            -- normal = Vector(0,-1,0)
            -- value = box.yMin
            -- xblock = false
          -- end
        -- end
      -- elseif x <= middle.x then
        -- if y > middle.y then
          -- -- up,left
          -- local relx = (middle.x - pos.x) / box.xScale
          -- local rely = (pos.y - middle.y) / box.yScale

          -- if relx > rely then
            -- --left
            -- normal = Vector(-1,0,0)
            -- value = box.xMin
            -- xblock = true
          -- else
            -- --up
            -- normal = Vector(0,1,0)
            -- value = box.yMax
            -- xblock = false
          -- end
        -- elseif y <= middle.y then
          -- -- down,left
          -- local relx = (middle.x - pos.x) / box.xScale
          -- local rely = (middle.y - pos.y) / box.yScale

          -- if relx > rely then
            -- --left
            -- normal = Vector(-1,0,0)
            -- value = box.xMin
            -- xblock = true
          -- else
            -- --down
            -- normal = Vector(0,-1,0)
            -- value = box.yMin
            -- xblock = false
          -- end
        -- end
      -- end

      -- Physics:BlockInAABox(unit, xblock, value, buffer, findClearSpace)

      -- if self.slide and IsPhysicsUnit(unit) then
        -- unit:AddPhysicsVelocity(math.max(0,unit:GetPhysicsVelocity():Dot(normal * -1)) * normal)
      -- end
    -- end
  -- })

-- Physics:CreateColliderProfile("aaboxreflect",
  -- {
    -- type = COLLIDER_AABOX,
    -- box = {Vector(0,0,0), Vector(200,100,500)},
    -- recollideTime = 0,
    -- skipFrames = 0,
    -- buffer = 0,
    -- block = true,
    -- findClearSpace = false,
    -- multiplier = 1,
    -- test = function(self, unit)
      -- return unit.IsRealHero and unit:IsRealHero() and unit:GetTeam() ~= unit:GetTeam() and IsPhysicsUnit(unit)
    -- end,
    -- action = function(self, box, unit)
      -- --PrintTable(box)
      -- local pos = unit:GetAbsOrigin()
      -- pos.z = 0

      -- local x = pos.x
      -- local y = pos.y
      -- local middle = box.middle
      -- local xblock = true
      -- local value = 0
      -- local normal = Vector(1,0,0)

      -- if x > middle.x then
        -- if y > middle.y then
          -- -- up,right
          -- local relx = (pos.x - middle.x) / box.xScale
          -- local rely = (pos.y - middle.y) / box.yScale

          -- if relx > rely then
            -- --right
            -- normal = Vector(1,0,0)
            -- value = box.xMax
            -- xblock = true
          -- else
            -- --up
            -- normal = Vector(0,1,0)
            -- value = box.yMax
            -- xblock = false
          -- end
        -- elseif y <= middle.y then
          -- -- down,right
          -- local relx = (pos.x - middle.x) / box.xScale
          -- local rely = (middle.y - pos.y) / box.yScale

          -- if relx > rely then
            -- --right
            -- normal = Vector(1,0,0)
            -- value = box.xMax
            -- xblock = true
          -- else
            -- --down
            -- normal = Vector(0,-1,0)
            -- value = box.yMin
            -- xblock = false
          -- end
        -- end
      -- elseif x <= middle.x then
        -- if y > middle.y then
          -- -- up,left
          -- local relx = (middle.x - pos.x) / box.xScale
          -- local rely = (pos.y - middle.y) / box.yScale

          -- if relx > rely then
            -- --left
            -- normal = Vector(-1,0,0)
            -- value = box.xMin
            -- xblock = true
          -- else
            -- --up
            -- normal = Vector(0,1,0)
            -- value = box.yMax
            -- xblock = false
          -- end
        -- elseif y <= middle.y then
          -- -- down,left
          -- local relx = (middle.x - pos.x) / box.xScale
          -- local rely = (middle.y - pos.y) / box.yScale

          -- if relx > rely then
            -- --left
            -- normal = Vector(-1,0,0)
            -- value = box.xMin
            -- xblock = true
          -- else
            -- --down
            -- normal = Vector(0,-1,0)
            -- value = box.yMin
            -- xblock = false
          -- end
        -- end
      -- end

      -- if self.block then
        -- Physics:BlockInAABox(unit, xblock, value, buffer, findClearSpace)
      -- end

      -- local newVelocity = unit.vVelocity
      -- if newVelocity:Dot(normal) >= 0 then
        -- return
      -- end

      -- unit:SetPhysicsVelocity(((-2 * newVelocity:Dot(normal) * normal) + newVelocity) * self.multiplier * 30)
    -- end
  -- })