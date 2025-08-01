pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
    -- TODO: Set up player character, objects, etc

    -- state initialization
    _upd = u_start_screen
    _drw = d_start_screen

    -- player initialization
    ship = {
        x = 64,
        y = 64,
        vel = create_vector(1,1),
        fuel_max = 500,
        fuel_left = 500,
        score = 0,
        sprite = 2,
        state = "drift", -- "drift" or "lock"
        target = "none"
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

    -- star positions for background
    stars = {}
    for i = 1, 50 do
        add(stars, {
            x = flr(rnd(128)),
            y = flr(rnd(128)),
            speed = rnd(0.5) + 0.2
        })
    end

    -- particles for flow field
    flow_params = {
        a = rnd(1) - .5,
        b = rnd(1) - .5,
        c = rnd(1) - .5,
        d = rnd(1) - .5
    }

    particles = {}
    for i = 1, 1000 do
        add(particles, {
            x = flr(rnd(128)),
            y = flr(rnd(128)),
            vx = rnd(1) - .5,
            vy = rnd(1) - .5,
            lifespan = rnd(64)
        })
    end

    -- global variables
    max_orbit_distance = 40
    max_speed = 8
    map_boundary = 40

    selected_idx = 1
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
        _upd = u_play_game
        _drw = d_play_game
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

    -- draw ship
    spr(ship.sprite, ship.x, ship.y)
    if (ship.target != "none") and (ship.state == "lock") then
        line(ship.x, ship.y, ship.target.x, ship.target.y, 8)
    end

    -- draw only hardcoded examples (2 bodies)
    for body in all(bodies) do
        circfill(body.x, body.y, body.size, body.color)
    end

end

function u_launch_phase()
    -- TODO PLAYER CHOOSES LAUNCH VELOCITY ANGLE

    _upd = u_play_game
    _drw = d_play_game

end

function d_launch_phase()
    -- TODO PLAYER CHOOSES LAUNCH VELOCITY ANGLE
end

function u_play_game()
    -- accept player input
    if btn(❎) then
        if ship.fuel_left >= 0 then
            ship.state = "lock"
        end
    else
        ship.state = "drift"
    end

    -- update positions of ship, celestial bodies, and particles
    move_ship()
    move_fuel_pickups()
    -- update particles
    for particle in all(particles) do
        particle.x = (particle.x + particle.vx + 128) % 128
        particle.y = (particle.y + particle.vy + 128) % 128
        vx, vy = flow(particle.x, particle.y)
        particle.vx = (particle.vx + vx) / 2
        particle.vy = (particle.vy + vy) / 2
        particle.lifespan = particle.lifespan - 1
        if particle.lifespan < 0 then
            particle.x = flr(rnd(128))
            particle.y = flr(rnd(128))
            particle.vx = rnd(1) - .5
            particle.vy = rnd(1) - .5
            particle.lifespan = rnd(64)
        end
    end
    
    -- end game condition when ship goes off screen
    if 
        ship.x < 0 - map_boundary or 
        ship.x > 128 + map_boundary or 
        ship.y < 0 - map_boundary or 
        ship.y > 128 + map_boundary 
    then
        _upd = u_end_screen
        _drw = d_end_screen
    end
end

function d_play_game()
    -- ADD PLAY GAME DRAW CODE HERE
    cls()
    camera(flr(ship.x - 64), flr(ship.y - 64))
    map()
    -- draw particles
    for particle in all(particles) do
        pset(particle.x, particle.y, 1)
    end
    -- draw celestial bodies
    for body in all(bodies) do
        circfill(body.x, body.y, body.size, body.color)
    end
    -- draw ship
    spr(ship.sprite, ship.x, ship.y)
    if (ship.target != "none") and (ship.state == "lock") then
        line(ship.x, ship.y, ship.target.x, ship.target.y, 8)
    end
    draw_fuel_pickups()
    
    camera(0,0)
    draw_fuel()
end

function u_end_screen() 
    -- ADD END SCREEN CODE HERE    
    if btn(❎) then
        -- TODO: create cooldown to prevent x carryover

        -- reinitialize game state
        _init()
        _upd = u_start_screen
        _drw = d_start_screen
    end
end

function d_end_screen()
    -- ADD END SCREEN DRAW CODE HERE
    draw_title()
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

    elseif _upd == u_end_screen then
        print_with_glow("game over", 20, 30, 7)
        draw_button(30, 100, "❎ play again", 1)
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

-- movement physics

function move_fuel_pickups()
    for fuel in all(fuel_snacks) do
        fuel.x += fuel.vel.x
        fuel.y += fuel.vel.y
        fuel.life -= 1/30

        if fuel.life <= 0 then
            del(fuel_snacks, fuel)
        end
    end

    if #fuel_snacks < max_fuel_snacks then
        add_fuel_pickup()
    end
end

function move_ship()
    if ship.state == "lock" then
        -- TODO: orbital mechanics
        ship.target = find_closest()

        if ship.target != "none" then
            -- consume fuel
            ship.fuel_left -= 1

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
            ship.vel.x = ship.vel.x+0.01*(new_vel.x-ship.vel.x)
            ship.vel.y = ship.vel.y+0.01*(new_vel.y-ship.vel.y)


            -- gravitational pull towards the center of the celestial body
            local gravity_pull = norm(create_vector(ship.target.x - ship.x, ship.target.y - ship.y))
            gravity_pull.x *= 0.003 * sqrt(ship.target.mass) * speed
            gravity_pull.y *= 0.003 * sqrt(ship.target.mass) * speed
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
    return closest
end

function flow(x, y, scale, speed)
    x = x/128 or 0
    y = y/128 or 0
    scale = scale or 2
    speed = speed or 1/16

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
        new_mass = 800
        new_size = rnd(2) + 2
        new_color = 13
    end
    local new_body = {
        x = rnd(128),
        y = rnd(128),
        mass = new_mass,
        size = new_size,
        color = new_color
    }
    add(bodies, new_body)
end

function add_fuel_pickup() 
    local origin_planet = rnd(bodies)
    local new_fuel_snack = {
        x = origin_planet.x,
        y = origin_planet.y,
        sprite = 14,
        life = rnd(6) + 6,
        vel = create_vector(rnd(1) - 0.5, rnd(1) - 0.5)
    }
    add(fuel_snacks, new_fuel_snack)
end

-- utility functions
function dst(o1,o2)
    return sqrt(sqr(o1.x-o2.x)+sqr(o1.y-o2.y))
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
00000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbb0007777770
0000000000000000ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb77b077000007
007007000cccccc0c0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bbbb7bb70000707
00077000cccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033bbbbbb77700707
000770000ccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033bbbbbb70000007
007007000ccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000333bbbbb77000707
00000000000cccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000333333070000007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033330077700007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077700007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777770
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
