pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
    -- TODO: Set up player character, objects, etc

    -- state initialization
    _upd = u_start_screen
    _drw = d_start_screen

    -- global variables
    max_orbit_distance = 100
    max_speed = 6
    map_size = 256
    map_boundary = map_size / 2 + max_orbit_distance + 40
    offset = 0 -- for screenshake
    highscore = 0

    -- ui variables
    ui_anim_timer = 0
	ui_anim_speed = 12
	ui_offset = 0

    intro_text = {[[working on a space station 
has never felt so boring...]],
[[to pass the time, you and 
your crewmates start testing 
out some new gravitational 
slingshot tech.]],
[[it's time for you to show off 
your interstellar 
maneuvering skills!]],
[[you're determined to
loop around a black hole,
and maybe even spot a 
wormhole.]],
[[just remember -- save enough 
fuel to get back home!]]}

    init_round()
end

function _update()
    ui_timer()
    _upd()
end

function _draw() 
    _drw()
end


-- states
function u_start_screen() 
    -- ADD START SCREEN CODE HERE
    if btn(❎) then
        _upd = u_intro
        _drw = d_intro
    end

    -- navigate choices
    -- if btnp(⬅️) then
    --     selected_idx -= 1
    --     if selected_idx < 1 then selected_idx = 2 end
    -- elseif btnp(➡️) then
    --     selected_idx += 1
    --     if selected_idx > 2 then selected_idx = 1 end
    -- end

    -- if btn(❎) and selected_idx == 1 then
    --     _upd = u_intro
    --     _drw = d_intro
    -- elseif btn(❎) and selected_idx == 2 then
    --     bodies_temp = deepcopy(bodies)
    --     _upd = u_intro
    --     _drw = d_intro
    -- end
end

function d_start_screen()
    -- ADD START SCREEN DRAW CODE HERE
    cls()
    map()
    draw_title()
end

function u_intro()
    update_particles()
    if btnp(🅾️) then
        intro_counter += 1
        intro_char_idx = 1
    end

    if intro_counter > #intro_text then
        _upd = u_launch_phase
        _drw = d_launch_phase
    end
    -- TODO ADD INTRO CODE HERE (tutorial mode)

    -- -- hardcode celestial body examples (2 planets)
    -- if not intro_initialized then
    --     bodies = {
    --         { x = 30, y = 70, size = 4 },
    --         { x = 110, y = 45, size = 8 }
    --     }
    --     intro_initialized = true -- flag to prevent reset every frame
    -- end

    -- if btn(❎) then
    --     ship.state = "lock"
    -- else
    --     ship.state = "drift"
    -- end

    -- move_ship()

    -- if btn(🅾️) then
    --     -- restore original randomized celestial bodies
    --     bodies = deepcopy(bodies_temp) 
    --     intro_initialized = false
        
    --     _upd = u_start_screen
    --     _drw = d_start_screen
    -- end
end

function d_intro()
    -- TODO ADD INTRO CODE HERE
    -- cls()
    -- map()
    -- print_with_glow("your rocket loop awaits", 20, 10, 7)
    -- print_hint("❎ to toggle gravity tether", 10, 105, 6, 0)
    -- print_hint("🅾️ to return to home screen", 10, 115, 6, 0)


    -- draw_ship()
    -- draw_lasso()

    -- -- draw only hardcoded examples (2 bodies)
    -- for body in all(bodies) do
    --     circfill(body.x, body.y, body.size, body.color)
    -- end

    update_camera_position()
    cls()
    camera(cam.x, cam.y)
    map()

    -- draw particles
    for particle in all(particles) do
        if dst(particle, create_vector(128,128)) >= map_boundary then
            pset(particle.x + ship.x / 4 - 256, particle.y + ship.y / 4 - 256, 5)
        else
            pset(particle.x + ship.x / 4 - 256, particle.y + ship.y / 4 - 256, 1)
        end
    end
    -- draw celestial bodies
    draw_bodies()
    -- draw portals around perimeter
    for portal in all(portals) do
        spr(portal.sprite, portal.x, portal.y)
    end
    draw_fuel_pickups()
    draw_station()
    
    draw_ship()

    camera(0,0)
    draw_intro_text(intro_text[intro_counter])
    print_hint("🅾️ next", 10, 115 + ui_offset, 7, 0)

end

function u_launch_phase()
    -- random launch angle
    -- if btnp(0) then
    --     ship.launch_angle = (ship.launch_angle - 0.05) % 1
    -- end
    -- if btnp(1) then
    --     ship.launch_angle = (ship.launch_angle + 0.05) % 1
    -- end

    if btn(🅾️) then
        ship.launch_countdown -= 1/30
        ship.launch_phase = true
        offset = (3 - ship.launch_countdown) / 2
    else
        ship.launch_countdown = 3
        ship.launch_phase = false
    end

    if ship.launch_countdown <= 0 then
        ship.vel.x = cos(rnd(1)) 
        ship.vel.y = sin((rnd(1)))
        
        current_message = "hold ❎ to lasso planets"
        message_life = 6
        _upd = u_play_game
        _drw = d_play_game
    end

    update_particles()
    


end

function d_launch_phase()
    update_camera_position()
    cls()
    camera(cam.x, cam.y)
    map()

    current_message = "hold 🅾️ to launch"
    message_life = 1

    -- draw particles
    for particle in all(particles) do
        if dst(particle, create_vector(128,128)) >= map_boundary then
            pset(particle.x + ship.x / 4 - 256, particle.y + ship.y / 4 - 256, 5)
        else
            pset(particle.x + ship.x / 4 - 256, particle.y + ship.y / 4 - 256, 1)
        end
    end
    -- draw celestial bodies
    draw_bodies()
    -- draw portals around perimeter
    for portal in all(portals) do
        spr(portal.sprite, portal.x, portal.y)
    end
    draw_fuel_pickups()
    draw_station()
    
    draw_ship()

    -- draw launch angle
    -- line(ship.x, ship.y, ship.x + ship.vel.x * 20, ship.y + ship.vel.y * 20, 9)
    -- draw launch countdown

    -- print instructions
    camera(0,0)
    -- print_hint("⬅️➡️ to choose launch angle", 2,2,7,3)
    -- print_hint("hold 🅾️ to launch", 2,12, 7,3)
    draw_message()
end

function u_play_game()
    -- accept player input
    if btn(❎) then
        if ship.fuel_left >= 0 then
            ship.state = "lock"
            add_ship_particle("engine")
            add_ship_particle("engine")
        end
    else
        ship.state = "drift"
        add_ship_particle("normal")
    end
    printh("ship location:\t" .. ship.x .. "\t" .. ship.y.. "\t" .. ship.vel.x.. "\t" .. ship.vel.y)

    -- scoring: 1 point every second you're alive
    ship.score += (1/30)
    -- update positions of ship, celestial bodies, and particles
    move_ship()
    move_fuel_pickups()

    -- check if ship flying into any portals
    activate_portal()

    -- update particles
    update_particles()
    update_ship_particles()
    -- smooth camera follow with teleport detection
    update_camera_position()
    
    -- end game condition when ship goes off screen
    local center_distance = dst(ship, create_vector(128,128))
    if center_distance >= map_boundary then
        _upd = u_end_screen
        _drw = d_end_screen
    end
end

function d_play_game()
    -- ADD PLAY GAME DRAW CODE HERE
    cls()
    camera(flr(cam.x), flr(cam.y))
    map()

    -- circfill(128,128, map_boundary, 1)

    -- draw particles
    for particle in all(particles) do
        pset(particle.x + ship.x / 4 - 256, particle.y + ship.y / 4 - 256, 1)
    end
    -- draw celestial bodies
    draw_bodies()
    -- draw portals around perimeter
    for portal in all(portals) do
        spr(portal.sprite, portal.x, portal.y)
    end
    draw_fuel_pickups()
    draw_station()

    -- draw ship
    draw_ship()
    draw_lasso()

        -- draw ship emitted particles
    for part in all(ship_particles) do
        circfill(part.x, part.y, part.size, part.color)
    end
    camera(0,0)
    draw_fuel()
    draw_score()
    draw_message()

end

function u_end_screen() 
    if not ending_initialized then
        ship.vel.x /= 3
        ship.vel.y /= 3
        ship.anim_speed = 20
        ending_initialized = true
        if ship.score >= highscore then
            new_high_score = true
            highscore = ship.score
        end

    end


    update_camera_position()

    -- slowly dock ship in the station
    if ship.landing_success then
        local dstx = ship.target.x - ship.x
        local dsty = ship.target.y - ship.y

        ship.x += dstx / 15
        ship.y += dsty / 15

        if abs(dstx) <= 1 then
            ship.x = ship.target.x
        end
        if abs(dsty) <= 1 then
            ship.y = ship.target.y
        end
    else
        ship.x += ship.vel.x
        ship.y += ship.vel.y
        if ship.anim_counter % 4 == 0 then
            add_ship_particle("normal") -- add sparse particles
        end
        ship.anim_speed = 20 -- slowed for dramatic effect
    end


    move_fuel_pickups()


    -- update particles
    update_particles()
    update_ship_particles()
    if btn(🅾️) then
        -- reinitialize game state
        init_round()
        _upd = u_start_screen
        _drw = d_start_screen
    end
end

function d_end_screen()
    -- ADD END SCREEN DRAW CODE HERE
    cls()
    camera(cam.x, cam.y)
    map()

    -- draw particles
    for particle in all(particles) do
        pset(particle.x, particle.y, 1)
    end
    -- draw celestial bodies
    draw_bodies()
    -- draw portals around perimeter
    for portal in all(portals) do
        spr(portal.sprite, portal.x, portal.y)
    end
    draw_fuel_pickups()
    draw_station()

    -- draw ship
    draw_ship()
    -- draw ship emitted particles
    for part in all(ship_particles) do
        circfill(part.x, part.y, part.size, part.color)
    end

    camera(0,0)
    if ship.landing_success == true then
        print_with_glow("you made it home!", 20, 20 + ui_offset, 7)
        print_with_glow("final score: " .. flr(ship.score), 20, 30 + ui_offset, 7)
        if new_high_score then
            print_with_glow("new high score!", 20, 50 + ui_offset, 7)
        end
    else
        print_with_glow("you drifted into the", 20, 30 + ui_offset, 7)
        print_with_glow("cold depths of space", 20, 40 + ui_offset, 7)
        if ship.last_target.type == "blackhole" then
            print_with_glow("watch out for black holes...", 20, 50 + ui_offset, 7)
        elseif ship.fuel_left <= 0 then
            print_with_glow("watch your fuel tank!", 20, 50 + ui_offset, 7)
        end
    end
    -- draw_button(30, 100, "🅾️ play again", 1)
    current_message = "🅾️ play again"
    message_life = 1/30
    draw_message()
end


-- start / end screen drawing functions
function draw_starry_bg()
    cls(0)
    for s in all(stars) do
        pset(s.x, s.y, 5 + rnd(2)) -- white/grey stars
        s.y += s.speed
        if s.y > 128 then
            s.y = 0
            s.x = flr(rnd(128))
        end
    end
end

function draw_title()
    draw_starry_bg()
    camera(ship.x - 64, ship.y - 64)
    draw_ship()

    camera(0,0)
    if _upd == u_start_screen then
        print_with_glow("starship loopers", 30, 30, 7)
        --draw_button(10, 100, "tutorial", selected_idx == 1)
        -- draw_button(40, 100, "start game", selected_idx == 2)
        current_message = "❎ start game"
        message_life = 1/30
        draw_message()

        if highscore > 0 then
            print_with_glow("best score: " .. flr(highscore), 30, 50 + ui_offset, 7)
        end
	end

end

function print_with_glow(str, x, y, col)
    -- draw shadow/glow offsets
    local glow_color = 3
    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                print(str, x + dx, y + dy, glow_color)
            end
        end
    end
    -- draw main text
    print(str, x, y, col)
end

function print_hint(txt, x, y, col, shadow)
    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx != 0 or dy != 0 then
                print(txt, x + dx, y + dy, shadow)
            end
        end
    end
    print(txt, x, y, col)
end

function draw_score()
    print_with_glow(flr(ship.score), 2,2 + ui_offset,7)
end

function draw_button(x, y, label, selected)
    local w = #label * 4 + 4
    if _upd == u_end_screen then -- give play again more padding
        w += 2
    end

    -- change button color (dark blue) if selected
    rectfill(x - 4, y - 2, x + w, y + 8, selected and 6 or 1)
    rect(x - 4, y - 2, x + w, y + 8, 7)

    print(label, x, y, 7)
end

function draw_message()
    if current_message != "" then
        text_width = #current_message * 4
        print(current_message, (64 - text_width / 2), 112 + ui_offset, 7)
        
        -- text_width = #current_message * 8
        -- upperx = 64 - text_width / 2
        -- uppery = 64 - 4
        -- lowerx = 64 + text_width / 2
        -- lowery = 64 - 4

        -- -- draw textbox
        -- circfill(upperx, 64, 5, 3)
        -- circfill(lowerx, 64, 5, 3)
        -- rectfill(upperx - 1, uppery - 1, lowerx + 1, lowery - 1, 3)
        padding = 4
        rect_x1 = 64 - text_width / 2 - padding
        rect_x2 = 64 + text_width/2 + padding + 1
        rect_y1 = 112 - padding
        rect_y2 = 112 + 4 + padding

        rect(rect_x1 - 1, rect_y1 + 1 + ui_offset, rect_x2 - 1, rect_y2 + 1 + ui_offset, 3)
        rect(rect_x1, rect_y1 + ui_offset, rect_x2, rect_y2 + ui_offset, 11)
        
        message_life -= (1/30)

        if message_life <= 0 then
            current_message = ""
        end
    else
    end

end

function draw_bodies()
    for body in all(bodies) do
        if body.type == "normal" then
            spr(body.sprite, body.x, body.y)
        elseif body.type == "blackhole" then

            circ(body.x + 2, body.y + 2, body.size, body.color[1])
            circ(body.x + 2, body.y - 1 +2 , body.size, body.color[2])
            circ(body.x + 1 + 2, body.y - 1 +2, body.size, body.color[3])

            local randomize = flr(rnd(10))
            if randomize == 1 then
                body.color[1] = rnd({7,8,9,10})
                body.color[2] = rnd({7,8,9,10})
                body.color[3] = rnd({7,8,9,10})
            end
        end
    end
end

function draw_fuel() 
    local fuel_width = max(flr(ship.fuel_left / ship.fuel_max  * 14) + 1, 0)
    if ship.fuel_left < ship.fuel_max / 3 then
        this_color = 8
    elseif ship.fuel_left < ship.fuel_max / 2 then
        this_color = 10
    else
        this_color = 11
    end 
    rectfill(119, 17 - fuel_width, 124, 17, this_color)
    -- overlaying fuel canister sprite on top
    spr(15, 118, 2)
    spr(31, 118, 10)
end

function draw_fuel_pickups()
    for fuel in all(fuel_snacks) do
        spr(fuel.sprite, fuel.x, fuel.y)
    end
end

function draw_station()
    sspr(96, 0, 16, 16, station.x - 6, station.y - 6)
end

function draw_lasso()
    if (ship.target != "none") and (ship.state == "lock") then
        line(ship.x, ship.y, ship.target.x + 3, ship.target.y + 3, 8)
    end
end

function draw_ship()
	ship.anim_counter += 1
	
	if ship.anim_counter >= ship.anim_speed then
		ship.anim_index = (ship.anim_index) % #ship.anim_frames + 1
		ship.anim_counter = 0
	end

	spr(ship.anim_frames[ship.anim_index], ship.x - 4, ship.y - 6)
end
-- movement physics
function move_fuel_pickups()
    for fuel in all(fuel_snacks) do
        fuel.x += fuel.vel.x
        fuel.y += fuel.vel.y
        fuel.life -= 1/30

        if fuel.life <= 0 then
            del(fuel_snacks, fuel)
        else
            -- check for collision with any black hole
            for body in all(bodies) do
                if body.type == "blackhole" and is_collision(fuel, body) then
                    del(fuel_snacks, fuel)
                    break
                end
            end
        end
    end

    if #fuel_snacks < max_fuel_snacks then
        add_fuel_pickup()
    end
end

function move_ship()
    -- decrement portal cooldown
    if ship.portal_cooldown > 0 then
        ship.portal_cooldown -= 1
    end

    if ship.state == "lock" then
        ship.target = find_closest()

        if ship.target != "none" then
            if ship.last_target != ship.target then
                ship.just_targeted = true
            else
                ship.just_targeted = false
            end

            ship.last_target = ship.target
            -- consume fuel
            ship.fuel_left -= 1
            
            if ship.fuel_left < ship.fuel_max / 3 then
                current_message = "low fuel!"
                message_life = 2
            end
            if ship.fuel_left < 0 then  
                current_message = "no fuel!"
                message_life = 2
                offset = 3

            end

            if ship.target.type == "blackhole" and ship.just_targeted then
                current_message = "bonus - whoah, a black hole!"
                message_life = 2
                ship.score += 50
            end

            if ship.target.type == "station" then
                land_ship()
            else
                ship.landing_countdown = 3
            end

            local distance = dst(ship, ship.target)
            -- clockwise and counterclockwise orbit vectors
            local vec1 = create_vector(- (ship.y - ship.target.y), (ship.x - ship.target.x))
            local vec2 = create_vector((ship.y - ship.target.y), - (ship.x - ship.target.x))
            -- find crossproduct to pick best vector with smallest angle of change
            local cross1 = ship.vel.x * vec1.y - ship.vel.y * vec1.x
            
            if cross1 > 0 then
                new_vel = vec1
            else
                new_vel = vec2
            end

            new_vel = norm(new_vel)
            -- TODO: make speed proportional to distance
            local speed = ((max_orbit_distance - distance) / max_orbit_distance) * max_speed
            
            -- lerp to transition into orbit
            ship.vel.x = ship.vel.x+0.003*(new_vel.x-ship.vel.x)
            ship.vel.y = ship.vel.y+0.003*(new_vel.y-ship.vel.y)

            -- gravitational pull towards the center of the celestial body
            local gravity_pull = create_vector(ship.target.x - ship.x, ship.target.y - ship.y)
            gravity_pull.x *= 0.0016 * ((max_orbit_distance - distance) / max_orbit_distance) * sqrt(ship.target.mass)
            gravity_pull.y *= 0.0016 * ((max_orbit_distance - distance) / max_orbit_distance) * sqrt(ship.target.mass)
            ship.vel.x += gravity_pull.x
            ship.vel.y += gravity_pull.y


        end
    end
    -- ship moves along same path (no friction in space!)
    ship.x += ship.vel.x
    ship.y += ship.vel.y

    -- check for fuel pickups
    for fuel in all(fuel_snacks) do
        local distance = dst(ship, fuel)
        if distance <= 12 then
            del(fuel_snacks, fuel)
            ship.fuel_left = min(ship.fuel_left + 100, ship.fuel_max)
            -- point bonus for refueling
            ship.score += 20
            offset = 2
            current_message = "bonus - refueled!"
            message_life = 1.5
        end
    end
end

function land_ship()
    ship.landing_countdown -= 1/30
    current_message = "hold 🅾️ to land"
    message_life = 1
    if ship.landing_countdown <= 0 then
        ship.landing_success = true
        _upd = u_end_screen
        _drw = d_end_screen
    end
end


function update_particles()
    for particle in all(particles) do
        particle.x = (particle.x + particle.vx + 512) % 512
        particle.y = (particle.y + particle.vy + 512) % 512
        vx, vy = flow(particle.x, particle.y)
        particle.vx = (particle.vx + vx) / 2
        particle.vy = (particle.vy + vy) / 2
        particle.lifespan = particle.lifespan - 1
        if particle.lifespan < 0 then
            particle.x = flr(rnd(512)) - 256
            particle.y = flr(rnd(512)) - 256
            particle.vx = rnd(1) - .5
            particle.vy = rnd(1) - .5
            particle.lifespan = rnd(64)
        end
    end

end

function is_collision(o1, o2)
    -- precheck to avoid numeric overflow problems in dst()
    local dx = abs(o1.x - o2.x)
    local dy = abs(o1.y - o2.y)
    local limit = o1.size + o2.size

    if dx > limit or dy > limit then
        return false
    end

    local dist = dst(o1, o2)
    return dist < limit
end
function update_camera_position()
    local target_cam_x = ship.x - 64
    local target_cam_y = ship.y - 64
    local cam_distance = sqrt(
        sqr(target_cam_x - cam.x) + 
        sqr(target_cam_y - cam.y)
    )
    
    -- if ship teleported far away, snap camera closer
    if cam_distance > 100 then
        cam.x = target_cam_x
        cam.y = target_cam_y
    else
        -- normal smooth follow
        cam.x += 0.3 * (target_cam_x - cam.x)
        cam.y += 0.3 * (target_cam_y - cam.y)
    end

    -- shake screen
    if offset >= 0 then
        local fade = 0.9
        local offset_x = 1.5 - rnd(3)
        local offset_y = 1.5 - rnd(3)
	    offset_x *= offset
	    offset_y *= offset

        cam.x += offset_x
        cam.y += offset_y

        offset *= fade

        if offset < 0.05 then
            offset = 0
        end
    end
    
end

function update_ship_particles()
    for part in all(ship_particles) do
        flowX, flowY = flow(part.x, part.y, 2, 0.5)
        part.x += part.vel.x + flowX
        part.y += part.vel.y + flowY
        part.lifespan -= 1/30
        if part.lifespan <= 0 then
            del(ship_particles, part)
        end
    end
end


function activate_portal()
    -- ship.portal_cooldown: 0 when no portal interaction
    -- ship.portal_target: the portal that the ship is going into. defined before the ship teleports

    if ship.portal_cooldown > 0 then
        printh(ship.portal_cooldown .. "\t" .. get_magnitude(ship.vel))
    end
    cooldown_duration = 50

    -- Neutral state
    if ship.portal_cooldown == 0 then
        for portal in all(portals) do
            if is_collision(ship, portal) then
                ship.portal_cooldown = cooldown_duration
                ship.portal_target = portal
                printh("target portal\t"..ship.portal_target.x.."\t"..ship.portal_target.y)
                printh(ship.portal_cooldown .. "\t" .. get_magnitude(ship.vel))

                local vec = norm(create_vector(ship.portal_target.x - ship.x, ship.portal_target.y - ship.y))
                local new_speed = max(0.8, get_magnitude(ship.vel) * .75)
                
                -- ship.vel.y = vec.y * new_speed
                -- ship.vel.x = vec.x * new_speed

                break
            end
        end
        return
    end

    -- teleport the ship
    if ship.portal_cooldown == flr(cooldown_duration * 5 / 8) then
        -- find another portal to teleport to
        local other_portals = {}
        for p in all(portals) do
            if p != ship.portal_target then
                add(other_portals, p)
            end
        end

        if #other_portals > 0 then
            local dest = rnd(other_portals)
            printh("dest portal\t"..dest.x.."\t"..dest.y)
            
            -- teleportation
            printh("teleport!")
            ship.x = dest.x
            ship.y = dest.y
            current_message = "bonus - whoah, a wormhole!"
            message_life = 2
            ship.score += 100

            local vec = norm(create_vector(station.x - dest.x, station.y - dest.y))
            printh("vec:\t" .. vec.x .. "\t" .. vec.y)
            local new_speed = get_magnitude(ship.vel)
            printh("new_speed:\t" .. new_speed)
            
            if vec.y * new_speed > 0 then
                ship.vel.y = max(min(vec.y * new_speed, 5), 0.1)
            else
                ship.vel.y = min(max(vec.y * new_speed, -5), -0.1)
            end

            if vec.x * new_speed > 0 then
                ship.vel.x = max(min(vec.x * new_speed, 5), 0.1)
            else
                ship.vel.x = min(max(vec.x * new_speed, -5), -0.1)
            end

            printh("ship.vel:\t" .. ship.vel.y .. "\t" .. ship.vel.x )
            ship.portal_target = nil
        end

        return
    end

    -- When the ship is entering a portal
    if ship.portal_target != nil then
        local vec = norm(create_vector(ship.portal_target.x - ship.x, ship.portal_target.y - ship.y))
        local new_speed = 3

        if ship.portal_cooldown == flr(cooldown_duration * 6 / 8) then
            new_speed = 0.8
            printh("slow")
        end

        ship.vel.y = vec.y * new_speed
        ship.vel.x = vec.x * new_speed
        return
    end

    -- leaving new portal
    if ship.portal_cooldown == flr(cooldown_duration * 3 / 8) then
            printh("speed up")
            ship.vel.y *= 5
            ship.vel.x *= 5
    end
end

function find_closest()
    local min_dist = max_orbit_distance
    local closest = "none"
    for body in all(bodies) do
        local distance = dst(ship, body)
        if distance <= min_dist then
            min_dist = distance
            closest = body
        end
    end

    local dst_from_station = dst(ship, station)
    if dst_from_station <= min_dist then
        closest = station
    end

    return closest
end

function flow(x, y, scale, speed)
    x = x/128 or 0
    y = y/128 or 0
    scale = scale or 2
    speed = speed or 1/12

    a = flow_params.a * scale
    b = flow_params.b * scale
    c = flow_params.c * scale
    d = flow_params.d * scale

    x1 = sin(a * y) + c * cos(a * x)
    y1 = sin(b * x) + d * cos(b * y)
    return (x1 - x) * speed, (y1 - y) * speed
end

-- initialization functions
function add_body(type, x, y)
    if type == "normal" then
        new_mass = rnd(80) + 10
        new_size = sqrt(new_mass) - 2
        new_color = 7
        sprite = rnd({10,11,26, 27})
    else -- for black holes
        new_mass = 600
        new_size = rnd(2) + 2
        colors = {7,8,9}
    end
    local new_body = {
        x = x,
        y = y,
        mass = new_mass,
        size = new_size,
        color = colors,
        type = type,
        sprite = sprite
    }
    add(bodies, new_body)
end

function add_ship_particle(type)
    if type == "engine" then
        if ship.fuel_left < ship.fuel_max / 3 then
            this_color = rnd({8, 9})
        elseif ship.fuel_left < ship.fuel_max / 2 then
            this_color = rnd({9, 10})
        else
            this_color = rnd({3, 11})
        end
    else
        this_color = rnd({6, 7})
    end
    local jitter = (rnd(1) - 0.5) / 20
    local new_part = {
        x = ship.x,
        y = ship.y,
        color = this_color,
        vel = create_vector(- (ship.vel.x + jitter) / 4, - (ship.vel.y + jitter) / 4),
        --vel = create_vector(0,0),
        lifespan = rnd(2) - 1,
        size = rnd({0.5, 0.5, 1})
    }
    add(ship_particles, new_part)
end

function add_fuel_pickup() 
    -- ensure fuel only originates from planets
    local planets = {}
    for body in all(bodies) do
        if body.type == "normal" then
            add(planets, body)
        end
    end

    if #planets > 0 then
        local origin_planet = rnd(planets)
        local new_fuel_snack = {
            x = origin_planet.x,
            y = origin_planet.y,
            sprite = 14,
            size = 6,
            life = rnd(6) + 6,
            vel = create_vector(rnd(1) - 0.5, rnd(1) - 0.5)
        }
        add(fuel_snacks, new_fuel_snack)
    end
end

function add_stars()
    local new_star = {
        x = flr(rnd(128)),
        y = flr(rnd(128)),
        speed = rnd(0.5) + 0.2
    }
    add(stars, new_star)
end

function rnd_outside_window()
    -- generates point somewhere outside a circular area
    local x, y
    local edge = flr(rnd(4))
    local map_boundary_with_padding = map_boundary - 80
    
    local edge_coord = flr((rnd(2) - 1) * 20)

    local angle = rnd(1)
    local newx = cos(angle) * (map_boundary_with_padding + edge_coord) + station.x
    local newy = sin(angle) * (map_boundary_with_padding + edge_coord) + station.y


    -- if edge == 0 then
    --     x = station.x + slidey_coord
    --     y = station.y - map_boundary_with_padding + edge_coord
    -- elseif edge == 1 then
    --     x = station.x + map_boundary_with_padding + edge_coord
    --     y = station.y + slidey_coord
    -- elseif edge == 2 then
    --     x = station.x + slidey_coord
    --     y = station.y + map_boundary_with_padding + edge_coord
    -- else
    --     x = station.x - map_boundary_with_padding + edge_coord
    --     y = station.y + slidey_coord
    -- end

    -- printh("rnd_outside_window():\t" .. x .. "\t" .. y)

    return newx, newy
end

function add_portals()
    local px, py = rnd_outside_window()
    local new_portal = {
        x = px,
        y = py,
        sprite = 3,
        size = 10
    }
    add(portals, new_portal)
end

-- utility functions
-- function dst(o1,o2)
--     return sqrt(sqr(o1.x-o2.x)+sqr(o1.y-o2.y))
-- end

function dst(o1, o2)
    local scale = 10
    local dx = flr(o1.x - o2.x) / scale
    local dy = flr(o1.y - o2.y) / scale
    return sqrt(sqr(dx) + sqr(dy)) * scale
end

function sqr(x) return x*x end

function create_vector(x_input, y_input) 
    return {x = x_input, y = y_input}
end

function get_magnitude(vec)
    local abs_x = abs(vec.x)
    local abs_y = abs(vec.y)
    local max_dim = max(abs_x, abs_y)

    if max_dim < 181 then
        return sqrt(sqr(vec.x) + sqr(vec.y))
    end

    local scale = 1
    while max_dim > 50 do
        max_dim /= 2
        scale *= 2
    end
    
    local scaled_x = vec.x / scale
    local scaled_y = vec.y / scale
    local magnitude = scale * sqrt(sqr(scaled_x) + sqr(scaled_y))
    return magnitude
end

function norm(vec)
    if vec.x == 0 and vec.y == 0 then
        return create_vector(0, 0)
    end

    local magnitude = get_magnitude(vec)

    if magnitude == 0 then
        return create_vector(0, 0)
    end

    return create_vector(vec.x / magnitude, vec.y / magnitude)

end

function deepcopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = deepcopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function init_round()
    intro_counter = 1
    intro_anim_timer = 0
    intro_anim_speed = 1
    intro_char_idx = 1

    ending_initialized = false 
    new_high_score = false

    selected_idx = 1
    -- space station
    station = {
        x = 128,
        y = 128,
        mass = 80,
        type = "station"
    }

    -- player initialization
    ship = {
        x = station.x + 2,
        y = station.y - 4,
        vel = create_vector(0,0),
        fuel_max = 350,
        fuel_left = 350,
        score = 0,
        sprite = 2,
        anim_frames = {2,18,34,34,18,2,18,50,50,18},
        anim_counter = 0,
        anim_speed = 6,
        anim_index = 1,
        size = 4,
        state = "drift", -- "drift" or "lock"
        target = "none",
        last_target = "none",
        just_targeted = false,
        launch_angle = 0,
        launch_countdown = 3,
        launch_phase = false,
        landing_countdown = 3,
        landing_success = false,
        portal_cooldown = 0,
        portal_target = create_vector(0,0)
    }
    -- celestial body initialization
    -- spaces them out on rings to avoid overlap
    bodies = {}
    rings = {40, 60, 80, 80, 80, 90, 90, 90, 100, 100, 100, 115, 128, 128}
    last_angle = 0
    max_black_holes = 3
    num_black_holes = 0
    for i = 1, #rings do
        local angle = (rnd(0.25) + 0.25)  + last_angle
        last_angle = angle
        local bodyx = (cos(angle) * rings[i]) + map_size / 2
        local bodyy = (sin(angle) * rings[i]) + map_size / 2
        if rings[i] > 80 and num_black_holes < max_black_holes then
            local type = rnd({"normal", "normal", "blackhole"})
            if type == "blackhole" then
                num_black_holes += 1
            end
            add_body(type, bodyx, bodyy)
        else
            add_body("normal", bodyx, bodyy)
        end
    end


    fuel_snacks = {}
    max_fuel_snacks = 8
    for i = 1, max_fuel_snacks do
        add_fuel_pickup()
    end

    portals = {}
    num_portals = 4
    for i = 1, num_portals do
        add_portals()
    end
    -- local new_portal = {
    --     x = 175,
    --     y = 180,
    --     sprite = 3,
    --     size = 10
    -- }
    -- add(portals, new_portal)
    -- stars for title screen background
    stars = {}
    num_stars = 50
    for i = 1, num_stars do
        add_stars()
    end

    -- particles for flow field
    flow_params = {
        a = rnd(1) - .5,
        b = rnd(1) - .5,
        c = rnd(1) - .5,
        d = rnd(1) - .5
    }

    particles = {}
    for i = 1, 500 do
        add(particles, {
            x = flr(rnd(512)-256),
            y = flr(rnd(512)-256),
            vx = rnd(1) - .5,
            vy = rnd(1) - .5,
            lifespan = rnd(64)
        })
    end

    ship_particles = {}
    current_message = ""
    message_life = 0
    
    -- camera perspective
    cam = { x = 0, y = 0 }

    printh("map_boundary:\t" .. map_boundary)
    printh("station:\t" .. station.x .. "\t" .. station.y)
end

function draw_intro_text(string)
    intro_anim_timer += 1
    if intro_anim_timer >= intro_anim_speed then
        intro_anim_timer = 0
        intro_char_idx = min(intro_char_idx + 1, #string)
    end
	x = 8
	y = 8
	-- declare bounds of the text box --
	x_start = 8
	x_limit = 112
	y_limit = 96
	for i = 1, #string do
		if (string[i] == "\n") then
			y += 8
			x = x_start
		else
			c = 7
			if intro_char_idx >= i then
                x = print(string[i], x, y + ui_offset, c)
			end
		end
	end
end

function ui_timer()
    -- ui animation timer
    -- called in every update frame (in _update())
    -- apply ui_offset to UI variables to make them animate
	ui_anim_timer += 1
	if ui_anim_timer >= ui_anim_speed then
		ui_anim_timer = 0
		ui_offset = (ui_offset + 1) % 2
	end
end
__gfx__
000000000000000000666600062212000000000000000000000000000000000000000000000000000000000000aaaa0000000000000000000bb0000007777770
0000000000000000056776602c16c612000000000000000000000000000000000000000000000000000000000aaa77a005660000000056603b7b000077000007
007007000cccccc005677760611c7662000000000000000000000000000000000000000000000000000eee009a9aa7aa06670000000066703bbb000070000707
00077000cccccccc05667760d26c771d000000000000000000000000000000000000000000000000008ee7e099aaaaaa05670000000056700330000077700707
000770000ccccccc05566660d211cc12000000000000000000000000000000000000000000000000008eeee089aa999a06670000000066700000000070000007
007007000ccccccc005556002d2111160000000000000000000000000000000000000000000000000088eee0999aaaaa06a7000000006a700000000077000707
00000000000cccc00a5656a002c26120000000000000000000000000000000000000000000000000000888000999989006a7006666006a700000000070000007
0000000000000000003b3b000011d600000000000000000000000000000000000000000000000000000000000099990000600667766006000000000077700007
000000000000000000666600000000000000000000000000000000000000000000000000000000000076700000cccc0006666677776666600000000070000007
00000000000000000567766000000000000000000000000000000000000000000000000000000000077767000cbb77c000600667766006000000000077000007
00000000000000000567776000000000000000000000000000000000000000000000000000000000d66776701bbcc7cb06a6006666006a600000000070000007
00000000000000000566776000000000000000000000000000000000000000000000000000000000d676777013bcccb306a7000000006a700000000077700007
00000000000000000556666000000000000000000000000000000000000000000000000000000000d6676660133bbccc06670000000066700000000070000007
00000000000000000a5556a0000000000000000000000000000000000000000000000000000000000dd666001113b33c05670000000056700000000077000007
0000000000000000005656000000000000000000000000000000000000000000000000000000000000ddd000011133c006670000000066700000000070000007
0000000000000000003b3b0000000000000000000000000000000000000000000000000000000000000000000011130005670000000056700000000007777770
00000000000000000066660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000567766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000567776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000566776a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000556666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000a055660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000036556b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000003b0033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000066660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000567766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000567776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000a566776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000555666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000066560a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000036556b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000003b0033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006060606060606060606060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0606060606060606060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0606060606060606060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0606060606060606060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006060606060606060606060606060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000060606060606060606060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010c00000000202502075120751207522075321d5521d5321d5320f5320f5320f5320f53224522245221b52218522185221552224522245520a5520a5520c5520f5520f5520f5520c5520a552000020000200002
__music__
00 00424344

