require 'load_image' 
require 'Object'
require 'Ball'
require 'Bot'
SDL	= require "SDL"
image	= require "SDL.image"
require 'Agent'
require 'gnuplot'

has_human = true
has_bot = true
has_minimap = true


local running	= true
disp = { }
local width	=  1920
local height	= 1080
local cam_width,cam_height = 336,336
local num_tiles = {80,45}
local tile_size = {width/num_tiles[1],height/num_tiles[2]}
local obj_size = {tile_size[1]/2,tile_size[2]/2}
frame_timer = torch.Timer()
local fps = 20
local dt = 1/fps
function get_pixels(graphics)
    h,w = graphics.h,graphics.w
    bytes = graphics.surf:getPixels()
    pic = torch.zeros(h,w)
    for r=1,h do
        for c=1,w do
            --print(r,c)
            pic[r][c] = string.byte(bytes,(r-1)*w*4+(c-1)*4+1)
        end   
    end
    return pic
end
function render(graphics,camera)
    temp = {}
    temp.w = tile_size[1]*graphics.scale
    temp.h = tile_size[2]*graphics.scale
    for r = 1,num_tiles[1] do
        for c=1,num_tiles[2] do
            temp.x = (tile_size[1]*(r-1) - camera.x)*graphics.scale
            temp.y = (tile_size[2]*(c-1) - camera.y)*graphics.scale
            graphics.rdr:copy(graphics.bg,tileset[tile_list[r][c] ], temp)
        end
    end
    for _,obj in pairs(col_objs) do
        obj:render(graphics,camera)
    end
end
local function get_tile_rect(r,c)
    local rect= {}
    rect.x = (r-1)*tile_size[1]
    rect.y = (c-1)*tile_size[2]
    rect.w = tile_size[1]
    rect.h = tile_size[2]
    return rect
end

--sets up all of the additional effects of a tiles type
--to be called whenever that type has changed
local function add_tile_effects(tile_type,row,col)
    grow_time[row][col] = 0
    if tile_type == 1 then
        col_tiles[(row-1)*num_tiles[1]+ col] = nil
    elseif tile_type == 2 then
        col_tiles[(row-1)*num_tiles[1]+ col] = get_tile_rect(row,col)
    elseif tile_type == 4 then
        grow_time[row][col] = 1
    elseif tile_type == 5 then
        local struct = {}
        struct.rect = get_tile_rect(row,col)
        struct.ind = torch.Tensor{row,col}
        table.insert(heal_tiles,struct)
    end
end

--changes an individual tile *not* a map
--as isn't switching tile_list by reference
local function change_tile(tile_type,row,col)
    tile_list[row][col] = tile_type
    add_tile_effects(tile_type,row,col)
end
local function load_tilemap(map)
    tile_list = map
    for x = 1,num_tiles[1] do
        for y = 1,num_tiles[2] do
            add_tile_effects(map[x][y],x,y)
        end
    end
end
local function generate_region()
    local region = {}
    --tilemap generate
    region.tile = torch.ones(num_tiles[1],num_tiles[2])
    tile_mask = torch.rand(region.tile:size()):gt(.95)
    region.tile[tile_mask] = 2
    --movable object generation
    region.objects = {}
    table.insert(region.objects,agent)
    --table.insert(region.objects,pokemon)
    ball = Ball(0,0,tile_size,'agent',{x=16*7+2,y=16*15+3,h=16,w=16})
    table.insert(region.objects,ball)
    return region
end
local function update_world_map()
    for i=1,world.w do
        for j=1,world.h do
            local img,img_pos
            img = wm.bg
            --TODO:have map icons mean something
            img_pos = tileset[torch.random(5)]
            local dest_pos = {x=(i-1)*wm.tile_size,y=(world.h-j)*wm.tile_size,w=wm.tile_size,h=wm.tile_size}
            wm.rdr:copy(img,img_pos,dest_pos)
            if i == world.x and j == world.y then
                img = wm.agent
                img_pos = {x=16*0+2,y=16*0+3,h=16,w=16}
                wm.rdr:copy(img,img_pos,dest_pos)
            end
        end
    end
    wm.rdr:present()
    wm.win:updateSurface()
end
local function change_region(x,y)
    --if not generated, then generate
    if next(world.region[x][y]) == nil then
        world.region[x][y] = generate_region()
    end
    load_tilemap(world.region[x][y].tile)
    col_objs = world.region[x][y].objects
    update_world_map()
end

local function get_tile_ind(rect)
    local x = rect.x+rect.w/2
    local y = rect.y+rect.w/2
    local r = math.floor(x/tile_size[1])+1
    local c = math.floor(y/tile_size[2])+1
    return r,c
end
local function collide(r1,r2)
    return r1.x + r1.w > r2.x and
        r1.x < r2.x + r2.w and
        r1.y + r1.h > r2.y and
        r1.y < r2.y + r2.h
end
local function initialize()
    --SDL.setHint('21','2')
    col_objs = {}
	local ret, err = SDL.init { SDL.flags.Video }
	if not ret then
		error(err)
	end

	local ret, err = image.init { image.flags.PNG }
	if not ret then
		error(err)
	end
    --monitor info, like resolution (w,h)
    desktop = SDL.getDesktopDisplayMode(0)


    --init world map
    --its standard x,y coords
    world = {}
    world.w = 10
    world.h = 7
    world.x = 1
    world.y = 1
    world.region = {}
    for i = 1,world.w do
        world.region[i] = {}
        for j = 1,world.h do
            world.region[i][j] = {}
        end
    end
    --TODO: encapulate all region aspects
    col_tiles = {}
    heal_tiles = {}


    disp.scale = 3
    bot = {}
    bot.timer = torch.Timer()
    bot.scale = 1/4
    bot.w,bot.h = cam_width*bot.scale,cam_height*bot.scale
    if has_human then
        disp.win, err = SDL.createWindow {
            title	= "Game",
            width	= cam_width*disp.scale,
            height	= cam_height*disp.scale,
        }
        --setup minimap--------------------------------------
        if has_minimap then
            mm = {}
            mm.timer = torch.Timer()
            mm.timer:reset()
            mm.scale = 1/4
            mm.camera = {x=0,y=0,w=width,h=height}
            mm.win, err = SDL.createWindow {
                title	= "Map",
                width	= width*mm.scale,
                height	= height*mm.scale,
            }
            mm.win:setPosition(desktop.w-width*mm.scale,0)
            --disp.win:setPosition(width*mm.scale,0)
            mm.surf = mm.win:getSurface()
            mm.rdr, err = SDL.createSoftwareRenderer(mm.surf,-1)
            mm.bg = load_image("res/pokeback.png",mm.rdr)
            mm.agent = load_image("res/overworld.png",mm.rdr)
        end
        --]]---------------------------------------------------
        --setup world map-------------------------------------
        wm = {}
        wm.tile_size = 20
        wm.win,err = SDL.createWindow {
            title = "World Map",
            width = world.w*wm.tile_size,
            height = world.h*wm.tile_size,
        }
        wm.win:setPosition(desktop.w-world.w*wm.tile_size,desktop.h/2)
        wm.surf = wm.win:getSurface()
        wm.rdr,err = SDL.createSoftwareRenderer(wm.surf,-1)
        wm.bg = load_image("res/pokeback.png",wm.rdr)
        wm.agent = load_image("res/overworld.png",wm.rdr)

        --]]---------------------------------------------------
        if has_bot then
            bot.win, err = SDL.createWindow {
                title	= "Pokemon",
                width	= cam_width*bot.scale,
                height	= cam_height*bot.scale,
            }
            bot.win_surf = bot.win:getSurface()
            --bottom right
            bot.win:setPosition(desktop.w-cam_width*bot.scale,desktop.h-cam_width*bot.scale)
        end
        disp.surf = disp.win:getSurface()
        disp.rdr, err = SDL.createSoftwareRenderer(disp.surf, -1)
        disp.bg = load_image("res/pokeback.png",disp.rdr)
        disp.agent = load_image("res/overworld.png",disp.rdr)
        -- Get the size of the bg
        local f, a, w, h = disp.bg:query()
        bg_w = w
        bg_h = h
        --human agent
        agent = Agent(width / 2 - bg_w / 2,
                   height / 2 - bg_h / 2,
                   tile_size,
                   'agent',
                   {x=16*0+2,y=16*0+3,h=16,w=16},cam_width,cam_height)
        camera = agent.camera
    end
    if has_bot then
        bot.surf = bot.win_surf or SDL.createRGBSurface(bot.w,bot.h) 
        bot.rdr, err = SDL.createSoftwareRenderer(bot.surf, -1)
        bot.agent = load_image("res/overworld.png",bot.rdr)
        bot.bg = load_image("res/pokeback.png",bot.rdr)
        local f, a, w, h = bot.bg:query()
        bg_w = w
        bg_h = h
        pokemon = Bot(width / 2 - bg_w / 2,
                   height / 2 - bg_h / 2,
                   tile_size,
                   'agent',
                   {x=16*4+2,y=16*14+3,h=16,w=16},cam_width,cam_height)
        pokemon.record = not has_human
    end


    tileset = {}
    --grass
    tileset[1] = {}
    tileset[1].x = bg_w/2+16*-2
    tileset[1].y = bg_h-2*16
    tileset[1].w = 16
    tileset[1].h = 16
    --wall
    tileset[2] = {}
    tileset[2].x = bg_w/2 - 16
    tileset[2].y = 16*4
    tileset[2].w = 16
    tileset[2].h = 16
    --tree
    tileset[3] = {}
    tileset[3].x = bg_w/2+16
    tileset[3].y = 16*4
    tileset[3].w = 16
    tileset[3].h = 16
    --short grass
    tileset[4] = {}
    tileset[4].x = bg_w/2+16*2
    tileset[4].y = 0
    tileset[4].w = 16
    tileset[4].h = 16
    --tall grass
    tileset[5] = {}
    tileset[5].x = bg_w/2+16
    tileset[5].y = 0
    tileset[5].w = 16
    tileset[5].h = 16



    tile_list = torch.ones(num_tiles[1],num_tiles[2])
    grow_time = torch.zeros(num_tiles[1],num_tiles[2])


    change_region(world.x,world.y)
    table.insert(col_objs,pokemon)
    

end
initialize()
local pressed = {}
while running do
    --[[
    local my_r,my_c = get_tile_ind(agent.pos)
    print(my_r,my_c)
    --]]
    frame_timer:reset()
	for e in SDL.pollEvent() do
		if e.type == SDL.event.Quit then
			running = false
		elseif e.type == SDL.event.KeyDown then
			--print(string.format("key down: %d -> %s", e.keysym.sym, SDL.getKeyName(e.keysym.sym)))
            local key_name = SDL.getKeyName(e.keysym.sym)
            if  key_name == 'Space' and not pressed[e.keysym.sym] then
                local rem_r,rem_c = get_tile_ind(agent.pos)
                grow_time[rem_r][rem_c] = 0
                --if plain dirt, wall
                if tile_list[rem_r][rem_c] == 1 then
                    change_tile(2,rem_r,rem_c)
                else --back to dirt
                    change_tile(1,rem_r,rem_c)
                end
            elseif key_name == 'P'and not pressed[e.keysym.sym] then
                local rem_r,rem_c = get_tile_ind(agent.pos)
                change_tile(4,rem_r,rem_c)
            elseif key_name == 'W'and not pressed[e.keysym.sym] then
                agent.dir[2] = agent.dir[2] -1
            elseif key_name == 'A'and not pressed[e.keysym.sym] then
                agent.dir[1] = agent.dir[1] -1
            elseif key_name == 'S' and not pressed[e.keysym.sym] then
                agent.dir[2] = agent.dir[2] + 1
            elseif key_name == 'D' and not pressed[e.keysym.sym] then
                agent.dir[1] = agent.dir[1] + 1
            elseif key_name == 'Escape' and not pressed[e.keysym.sym] then
                running = false
            elseif key_name == 'Left' and not pressed[e.keysym.sym] then
                world.x = torch.random(world.w)
                world.y = torch.random(world.h)
                print(world.x,world.y)
                change_region(world.x,world.y)
            elseif key_name == 'Down' and not pressed[e.keysym.sym] then
                camera = pokemon.camera
            elseif key_name == 'Up' and not pressed [e.keysym.sym] then
                print('say cheese!')
                pic = get_pixels(bot)
                gnuplot.imagesc(pic)
                gnuplot.plotflush()
            end
            pressed[e.keysym.sym] = true
        elseif e.type == SDL.event.KeyUp then
            local key_name = SDL.getKeyName(e.keysym.sym)
            if key_name == 'W' then
                agent.dir[2] = agent.dir[2] +1
            elseif key_name == 'A' then
                agent.dir[1] = agent.dir[1] +1
            elseif key_name == 'S' then
                agent.dir[2] = agent.dir[2] - 1
            elseif key_name == 'D'  then
                agent.dir[1] = agent.dir[1] - 1
            end
            pressed[e.keysym.sym] = false
		end
	end
    --render-------------------------------
    --TODO:build up a big surface and then render that
    -- dirty flags, etc

    --
    if has_bot then
        if bot.timer:time().real > (1/fps)*2 then
            bot.timer:reset()
                
            render(bot,pokemon.camera)
            if not has_human then
                pic = get_pixels(bot)
                pokemon:forward(pic)
            else
                pokemon:forward()
                bot.rdr:present()
                bot.win:updateSurface()
            end
            --gnuplot.imagesc(pic)
            --gnuplot.plotflush()
        end
        
    end
    if has_human then
        if has_minimap then
            if mm.timer:time().real > (1/fps)*10 then
                mm.timer:reset()
                render(mm,mm.camera)
                mm.rdr:present()
                mm.win:updateSurface()
            end
        end
        render(disp,camera)
        disp.rdr:present()
        disp.win:updateSurface()
    end
    --]]
    --handle collisions----------------------------------- 
    local kill = {}
    for _,obj in pairs(col_objs) do
        --movement 
        obj:handle_movement(dt)
        --static/dynamic collisions
        for _,tile in pairs(col_tiles) do
            if collide(tile,obj.pos) then
                obj:handle_col({pos = tile,contact_damage = 0})
            end
        end
        for k,tile in pairs(heal_tiles) do
            if collide(tile.rect,obj.pos) then
                obj:handle_col({pos = tile.rect,contact_damage = -.1})
                table.insert(kill,k)
                tile_list[tile.ind[1] ][tile.ind[2] ] = 1
            end
        end
        --dynamic/dynamic collisions
        for _,obj2 in pairs(col_objs) do
            if obj ~= obj2 and  collide(obj.pos,obj2.pos) then
                obj:handle_col(obj2)
                obj2:handle_col(obj)
            end
        end
        --boundary collisions
        local hit = obj:handle_bounds(width,height)
        if obj == agent and hit:ne(0):any() then 
            if hit[1] == -1 then
                world.x = world.x+hit[1]
                if world.x < 1 then
                    world.x = 1
                else
                    agent:set_position(width-agent.pos.w*2,agent.pos.y)
                end
            elseif hit[1] == 1 then
                world.x = world.x+hit[1]
                if world.x > world.w then
                    world.x = world.w
                else
                    agent:set_position(agent.pos.w*2,agent.pos.y)
                end
            elseif hit[2] == -1 then
                world.y = world.y+hit[2]
                if world.y < 1 then
                    world.y = 1
                else
                    agent:set_position(agent.pos.x,agent.pos.h*2)
                end
            elseif hit[2] == 1 then
                world.y = world.y+hit[2]
                if world.y > world.h then
                    world.y = world.h
                else
                    agent:set_position(agent.pos.x,height-agent.pos.h*2)
                end
            end

            change_region(world.x,world.y)
        end
    end
    --remove dead tiles
    for i = 1,#kill do
        table.remove(heal_tiles,kill[i])
    end
    --heal tile logic----------------
    local grow_mask = grow_time:gt(0)
    grow_time[grow_mask] = grow_time[grow_mask] + 1
    local fully_grown = grow_time:gt(50)
    local num_grown = fully_grown:sum()
    if num_grown  > 0 then
        local inds = fully_grown:nonzero()
        for i= 1,num_grown do
            change_tile(5,inds[i][1],inds[i][2])
        end
        --[[
        grow_time[fully_grown] = 0
        tile_list[fully_grown] = 5
        for i= 1,num_grown do
            local struct = {}
            struct.rect = get_tile_rect(inds[i][1],inds[i][2])
            struct.ind = inds[i]
            table.insert(heal_tiles,struct)
        end
        --]]
    end
    local extra_time = (1/fps - frame_timer:time().real)*1000
    if extra_time > 0 then
	   SDL.delay(extra_time)
    else
        --print('lagging by:',-1/(extra_time/1000),' fps')
        print('fps:',math.ceil(1 / frame_timer:time().real))
    end
end
