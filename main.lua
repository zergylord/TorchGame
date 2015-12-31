require 'load_image' 
require 'Object'
require 'Ball'
SDL	= require "SDL"
image	= require "SDL.image"
require 'Agent'
require 'gnuplot'

has_human = true
has_bot = true

local running	= true
local disp	= { }
local width	=  1920
local height	= 1080
local cam_width,cam_height = 336,336
local num_tiles = {80,45}
local tile_size = {width/num_tiles[1],height/num_tiles[2]}
local obj_size = {tile_size[1]/2,tile_size[2]/2}
timer = torch.Timer()
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
    --TODO: try surface rendering (has pixels)
    --e.g. sur = win:getSurface() sur:blit(other sur)
    disp.scale = 3
    bot = {}
    bot.scale = 1/4
    bot.w,bot.h = cam_width*bot.scale,cam_height*bot.scale
    if has_human then
        win, err = SDL.createWindow {
            title	= "Game",
            width	= cam_width*disp.scale,
            height	= cam_height*disp.scale,
        }
        if has_bot then
            interface, err = SDL.createWindow {
                title	= "Pokemon",
                width	= cam_width*bot.scale,
                height	= cam_height*bot.scale,
            }
            inter_surf = interface:getSurface()
        end
        win_surf = win:getSurface()
        rdr, err = SDL.createSoftwareRenderer(win_surf, -1)
        --setup global disp
        disp.bg = load_image("pokeback.png",rdr)
        disp.agent = load_image("overworld.png",rdr)
        disp.win	= win
        disp.rdr	= rdr
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
        table.insert(col_objs,agent)
        camera = agent.camera
    end
    if has_bot then
        if has_human then
            bot.surf = inter_surf  
        else
            bot.surf = SDL.createRGBSurface(bot.w,bot.h) 
        end
        bot.rdr, err = SDL.createSoftwareRenderer(bot.surf, -1)
        bot.agent = load_image("overworld.png",bot.rdr)
        bot.bg = load_image("pokeback.png",bot.rdr)
        local f, a, w, h = bot.bg:query()
        bg_w = w
        bg_h = h
        pokemon = Agent(width / 2 - bg_w / 2,
                   height / 2 - bg_h / 2,
                   tile_size,
                   'agent',
                   {x=16*4+2,y=16*14+3,h=16,w=16},cam_width,cam_height)
        table.insert(col_objs,pokemon)
    end


    --ball = Ball(0,0,tile_size,bg,{x=16*22,y=16*10,w=16,h=16})
    ball = Ball(0,0,tile_size,'agent',{x=16*7+2,y=16*15+3,h=16,w=16})
    table.insert(col_objs,ball)

    tile_list = torch.ones(num_tiles[1],num_tiles[2])
    grow_time = torch.zeros(num_tiles[1],num_tiles[2])
end
local function get_tile_ind(rect)
    local x = rect.x+rect.w/2
    local y = rect.y+rect.w/2
    local r = math.floor(x/tile_size[1])+1
    local c = math.floor(y/tile_size[2])+1
    return r,c
end
local function get_tile_rect(r,c)
    local rect= {}
    rect.x = (r-1)*tile_size[1]
    rect.y = (c-1)*tile_size[2]
    rect.w = tile_size[1]
    rect.h = tile_size[2]
    return rect
end
local function collide(r1,r2)
    return r1.x + r1.w > r2.x and
        r1.x < r2.x + r2.w and
        r1.y + r1.h > r2.y and
        r1.y < r2.y + r2.h
end
initialize()
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
local pressed = {}
local col_tiles = {}
local heal_tiles = {}
local function change_tile(tile_type,row,col)
    
end
while running do
    timer:reset()
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
                    tile_list[rem_r][rem_c] = 2
                    col_tiles[(rem_r-1)*tile_size[1]+ rem_c] = get_tile_rect(rem_r,rem_c)
                else --back to dirt
                    tile_list[rem_r][rem_c] = 1
                    col_tiles[(rem_r-1)*tile_size[1]+rem_c] = nil
                end
            elseif key_name == 'P'and not pressed[e.keysym.sym] then
                local rem_r,rem_c = get_tile_ind(agent.pos)
                if tile_list[rem_r][rem_c] == 1 then
                    grow_time[rem_r][rem_c] = 1
                    tile_list[rem_r][rem_c] = 4
                end
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
        pic = get_pixels(bot)
        render(bot,pokemon.camera)
        --gnuplot.imagesc(pic)
        --gnuplot.plotflush()
        --bot_model:forward(pic)
    end
    if has_human then
        render(disp,camera)
        disp.rdr:present()
        win:updateSurface()
        if has_bot then
            bot.rdr:present()
            interface:updateSurface()
        end
    end
    --]]
    --handle collisions----------------------------------- 
    for _,obj in pairs(col_objs) do
        --movement 
        obj:handle_movement(dt)
        --static/dynamic collisions
        for _,tile in pairs(col_tiles) do
            if collide(tile,obj.pos) then
                obj:handle_col({pos = tile,contact_damage = 0})
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
        obj:handle_bounds(width,height)
    end
    --[[heal tile logic----------------
    local kill = {}
    for k,v in pairs(heal_tiles) do
        if collide(agent.pos,v.rect) then
            print('healed!')
            agent.hp = agent.hp + .1
            print(agent.hp)
            table.insert(kill,k)
            tile_list[v.ind[1] ][v.ind[2] ] = 1
        end
    end
    for i = 1,#kill do
        table.remove(heal_tiles,kill[i])
    end
    local grow_mask = grow_time:gt(0)
    grow_time[grow_mask] = grow_time[grow_mask] + 1
    local fully_grown = grow_time:gt(500)
    local num_grown = fully_grown:sum()
    if num_grown  > 0 then
        grow_time[fully_grown] = 0
        tile_list[fully_grown] = 5
        local inds = fully_grown:nonzero()
        for i= 1,num_grown do
            local struct = {}
            struct.rect = get_tile_rect(inds[i][1],inds[i][2])
            struct.ind = inds[i]
            table.insert(heal_tiles,struct)
            print(heal_tiles)
        end
    end
    --]]
    local extra_time = (1/fps - timer:time().real)*1000
    if extra_time > 0 then
	   SDL.delay(extra_time)
    else
        --print('lagging by:',-1/(extra_time/1000),' fps')
        print('fps:',math.ceil(1 / timer:time().real))
    end
end
