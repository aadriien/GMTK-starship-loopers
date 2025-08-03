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


    ending_initialized = false 

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
        x = station.x,
        y = station.y,
        vel = create_vector(0,0),
        fuel_max = 250,
        fuel_left = 250,
        score = 0,
        sprite = 2,
        anim_frames = {2,18,34,34,18,2,18,50,50,18},
        anim_counter = 0,
        anim_speed = 6,
        anim_index = 1,
        size = 4,
        state = "drift", -- "drift" or "lock"
        target = "none",
        launch_angle = 0,
        launch_countdown = 3,
        launch_phase = false,
        landing_countdown = 3,
        landing_success = false,
        portal_cooldown = 0
    }
    -- celestial body initialization
    bodies = {}
    num_bodies = 6
    num_black_holes = 2
    for i = 1, num_bodies do 
        add_body("normal")
    end
    for i = 1, num_black_holes do 
        add_body("blackhole")
    end

    fuel_snacks = {}
    max_fuel_snacks = 3
    for i = 1, max_fuel_snacks do
        add_fuel_pickup()
    end

    portals = {}
    num_portals = 5
    for i = 1, num_portals do
        add_portals()
    end

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
    for i = 1, 1 do
        add(particles, {
            x = flr(rnd(512)-256),
            y = flr(rnd(512)-256),
            vx = rnd(1) - .5,
            vy = rnd(1) - .5,
            lifespan = rnd(64)
        })
    end

    ship_particles = {}
    
    -- camera perspective
    cam = { x = 0, y = 0 }


end

function _update()
    _upd()
end

function _draw() 
    _drw()
end


-- states
function u_start_screen() 
    -- ADD START SCREEN CODE HERE

    -- navigate choices
    if btnp(⬅️) then
        selected_idx -= 1
        if selected_idx < 1 then selected_idx = 2 end
    elseif btnp(➡️) then
        selected_idx += 1
        if selected_idx > 2 then selected_idx = 1 end
    end

    if btn(❎) and selected_idx == 1 then
        _upd = u_launch_phase
        _drw = d_launch_phase
    elseif btn(❎) and selected_idx == 2 then
        bodies_temp = deepcopy(bodies)
        _upd = u_intro
        _drw = d_intro
    end
end

function d_start_screen()
    -- ADD START SCREEN DRAW CODE HERE
    cls()
    map()
    draw_title()
end

function u_intro()
    -- TODO ADD INTRO CODE HERE (tutorial mode)

    -- hardcode celestial body examples (2 planets)
    if not intro_initialized then
        bodies = {
            { x = 30, y = 70, size = 4 },
            { x = 110, y = 45, size = 8 }
        }
        intro_initialized = true -- flag to prevent reset every frame
    end

    if btn(❎) then
        ship.state = "lock"
    else
        ship.state = "drift"
    end

    move_ship()

    if btn(🅾️) then
        -- restore original randomized celestial bodies
        bodies = deepcopy(bodies_temp) 
        intro_initialized = false
        
        _upd = u_start_screen
        _drw = d_start_screen
    end
end

function d_intro()
    -- TODO ADD INTRO CODE HERE
    cls()
    map()
    print_with_glow("your rocket loop awaits", 20, 10, 7)
    print_hint("❎ to toggle gravity tether", 10, 105, 6, 0)
    print_hint("🅾️ to return to home screen", 10, 115, 6, 0)


    draw_ship()
    draw_lasso()

    -- draw only hardcoded examples (2 bodies)
    for body in all(bodies) do
        circfill(body.x, body.y, body.size, body.color)
    end

end

function u_launch_phase()
    -- TODO PLAYER CHOOSES LAUNCH VELOCITY ANGLE
    if btnp(0) then
        ship.launch_angle = (ship.launch_angle - 0.05) % 1
    end
    if btnp(1) then
        ship.launch_angle = (ship.launch_angle + 0.05) % 1
    end

    ship.vel.x = cos(ship.launch_angle) 
    ship.vel.y = - sin(ship.launch_angle)

    if btn(🅾️) then
        ship.launch_countdown -= 1/30
        ship.launch_phase = true
        offset = (3 - ship.launch_countdown) / 2
    else
        ship.launch_countdown = 3
        ship.launch_phase = false
    end

    if ship.launch_countdown <= 0 then
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
    -- draw particles
    for particle in all(particles) do
        if dst(particle, create_vector(128,128)) >= map_boundary then
            pset(particle.x + ship.x / 4 - 256, particle.y + ship.y / 4 - 256, 5)
        else
            pset(particle.x + ship.x / 4 - 256, particle.y + ship.y / 4 - 256, 1)
        end
    end
    -- draw celestial bodies
    for body in all(bodies) do
        circfill(body.x, body.y, body.size, body.color)
    end
    -- draw portals around perimeter
    for portal in all(portals) do
        spr(portal.sprite, portal.x, portal.y)
    end
    draw_fuel_pickups()
    draw_station()
    
    draw_ship()

    -- draw launch angle
    line(ship.x, ship.y, ship.x + ship.vel.x * 20, ship.y + ship.vel.y * 20, 9)
    -- draw launch countdown
    if ship.launch_phase == true then
        print(ship.launch_countdown) 
    end
    -- print instructions
    camera(0,0)
    print_hint("⬅️➡️ to choose launch angle", 2,2,7,3)
    print_hint("hold 🅾️ to launch", 2,12, 7,3)

end

function u_play_game()
    -- accept player input
    if btn(❎) then
        if ship.fuel_left >= 0 then
            ship.state = "lock"
            add_ship_particle(rnd({3,11}))
            add_ship_particle(rnd({3,11}))
        end
    else
        ship.state = "drift"
        add_ship_particle(rnd({6,7}))
    end

    -- scoring: 1 point every second you're alive
    ship.score += (1/30)
    -- update positions of ship, celestial bodies, and particles
    move_ship()
    move_fuel_pickups()

    -- check if ship flying into any portals
    -- activate_portal()

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
    for body in all(bodies) do
        circfill(body.x, body.y, body.size, body.color)
    end
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
end

function u_end_screen() 
    if not ending_initialized then
        ship.vel.x /= 3
        ship.vel.y /= 3
        ship.anim_speed = 20
        ending_initialized = true
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
            add_ship_particle(rnd({6})) -- add sparse particles
        end
        ship.anim_speed = 20 -- slowed for dramatic effect
    end


    move_fuel_pickups()


    -- update particles
    update_particles()
    update_ship_particles()
    if btn(🅾️) then
        -- reinitialize game state
        _init()
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
    for body in all(bodies) do
        circfill(body.x, body.y, body.size, body.color)
    end
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
    print_with_glow("game over", 20, 30, 7)
    if ship.landing_success == true then
        print_with_glow("final score: ", 20, 40, 7)
        print_with_glow(flr(ship.score), 20, 50, 7)
    else
        print_with_glow("you drifted into the", 20, 40, 7)
        print_with_glow("cold depths of space", 20, 50, 7)
    end
    draw_button(30, 100, "🅾️ play again", 1)
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
    
    if _upd == u_start_screen then
        print_with_glow("starship loopers", 10, 30, 7)
        draw_button(10, 100, "tutorial", selected_idx == 1)
        draw_button(60, 100, "start game", selected_idx == 2)
        print_hint("❎ to select", 25, 115, 6, 0)
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
    print_with_glow(flr(ship.score), 2,2,7)
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

function draw_fuel() 
    local fuel_width = max(flr(ship.fuel_left / ship.fuel_max  * 14) + 1, 0)
    rectfill(119, 17 - fuel_width, 124, 17, 11)
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
        line(ship.x, ship.y, ship.target.x, ship.target.y, 8)
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
            -- consume fuel
            ship.fuel_left -= 1
            
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
        if distance <= 8 then
            del(fuel_snacks, fuel)
            ship.fuel_left = min(ship.fuel_left + 100, ship.fuel_max)
            -- point bonus for refueling
            ship.score += 20
        end
    end
end

function land_ship()
    ship.landing_countdown -= 1/30

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

function is_collision(obj_a, obj_b)
    local dist = dst(obj_a, obj_b)
    return dist < obj_a.size + obj_b.size
end

function update_camera_position()
    -- local target_cam_x = ship.x - 64
    -- local target_cam_y = ship.y - 64
    -- local cam_distance = sqrt(
    --     sqr(target_cam_x - cam.x) + 
    --     sqr(target_cam_y - cam.y)
    -- )
    
    -- -- if ship teleported far away, snap camera closer
    -- if cam_distance > 100 then
    --     cam.x = target_cam_x
    --     cam.y = target_cam_y
    -- else
    --     -- normal smooth follow
    --     cam.x += 0.3 * (target_cam_x - cam.x)
    --     cam.y += 0.3 * (target_cam_y - cam.y)
    -- end
    cam.x = ship.x - 64
    cam.y = ship.y - 64
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
    -- don't activate if in cooldown
    if ship.portal_cooldown > 0 then
        return
    end
    
    -- check if ship intersecting with any portals
    for portal in all(portals) do
        if is_collision(ship, portal) then
            -- find another portal to teleport to
            local other_portals = {}
            for p in all(portals) do
                if p != portal then
                    add(other_portals, p)
                end
            end

            if #other_portals > 0 then
                local dest = rnd(other_portals)
                
                -- instant teleportation
                ship.x = dest.x
                ship.y = dest.y
                
                -- portal cooldown to prevent immediate re-teleport
                ship.portal_cooldown = 45
            end

            break
        end
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
function add_body(type)
    if type == "normal" then
        new_mass = rnd(80) + 10
        new_size = sqrt(new_mass) - 2
        new_color = 7
    else -- for black holes
        new_mass = 600
        new_size = rnd(2) + 2
        new_color = 13
    end
    local new_body = {
        x = rnd(256),
        y = rnd(256),
        mass = new_mass,
        size = new_size,
        color = new_color,
        type = type
    }
    add(bodies, new_body)
end

function add_ship_particle(color)
    local jitter = (rnd(1) - 0.5) / 20
    local new_part = {
        x = ship.x,
        y = ship.y,
        color = color,
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
    local x, y

    if rnd(1) < 0.5 then
        -- vertical edge strip
        if rnd(1) < 0.5 then
            x = -20 + flr(rnd(20))
        else
            x = map_size + flr(rnd(20)) 
        end
        y = flr(rnd(map_size))
    else
        -- horizontal edge strip
        if rnd(1) < 0.5 then
            y = -20 + flr(rnd(20)) 
        else
            y = map_size + flr(rnd(20)) 
        end
        x = flr(rnd(map_size)) 
    end

    return x, y
end

function add_portals()
    local px, py = rnd_outside_window()
    local new_portal = {
        x = px,
        y = py,
        sprite = 3,
        size = 4
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

function norm(vec)
    local magnitude = sqrt(sqr(vec.x) + sqr(vec.y))
    
    return create_vector((vec.x / magnitude), (vec.y / magnitude))
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



__gfx__
000000000000000000666600062212000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbb0007777770
0000000000000000056776602c16c612000000000000000000000000000000000000000000000000000000000000000005660000000056600bbb77b077000007
007007000cccccc005677760611c7662000000000000000000000000000000000000000000000000000000000000000006670000000066703bbbb7bb70000707
00077000cccccccc05667760d26c771d0000000000000000000000000000000000000000000000000000000000000000056700000000567033bbbbbb77700707
000770000ccccccc05566660d211cc120000000000000000000000000000000000000000000000000000000000000000066700000000667033bbbbbb70000007
007007000ccccccc005556002d211116000000000000000000000000000000000000000000000000000000000000000006a7000000006a70333bbbbb77000707
00000000000cccc00a5656a002c26120000000000000000000000000000000000000000000000000000000000000000006a7006666006a700333333070000007
0000000000000000003b3b000011d600000000000000000000000000000000000000000000000000000000000000000000600667766006000033330077700007
00000000000000000066660000000000000000000000000000000000000000000000000000000000000000000000000006666677776666600000000070000007
00000000000000000567766000000000000000000000000000000000000000000000000000000000000000000000000000600667766006000000000077000007
00000000000000000567776000000000000000000000000000000000000000000000000000000000000000000000000006a6006666006a600000000070000007
00000000000000000566776000000000000000000000000000000000000000000000000000000000000000000000000006a7000000006a700000000077700007
00000000000000000556666000000000000000000000000000000000000000000000000000000000000000000000000006670000000066700000000070000007
00000000000000000a5556a000000000000000000000000000000000000000000000000000000000000000000000000005670000000056700000000077000007
00000000000000000056560000000000000000000000000000000000000000000000000000000000000000000000000006670000000066700000000070000007
0000000000000000003b3b0000000000000000000000000000000000000000000000000000000000000000000000000005670000000056700000000007777770
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

