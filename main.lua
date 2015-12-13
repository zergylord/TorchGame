require 'load_image' 
require 'Ball'
local SDL	= require "SDL"
local image	= require "SDL.image"
local agent = require 'agent'

local running	= true
local graphics	= { }
local width	= 640
local height	= 480
local num_tiles = {20,20}
local tile_size = {width/num_tiles[1],height/num_tiles[2]}
local function initialize()
	local ret, err = SDL.init { SDL.flags.Video }
	if not ret then
		error(err)
	end

	local ret, err = image.init { image.flags.PNG }
	if not ret then
		error(err)
	end

	local win, err = SDL.createWindow {
		title	= "07 - Bouncing bg",
		width	= width,
		height	= height
	}

	if not win then
		error(err)
	end

	rdr, err = SDL.createRenderer(win, -1)
	if not rdr then
		error(err)
	end

	-- Set to white for the bg
	rdr:setDrawColor(0xFFFFFF)
    local bg = load_image("pokeback.png",rdr)

	-- Store in global graphics
	graphics.win	= win
	graphics.rdr	= rdr
	graphics.bg	= bg

	-- Get the size of the bg
	local f, a, w, h = bg:query()
    graphics.bg_w = w
    graphics.bg_h = h

    agent.init(width / 2 - w / 2,
               height / 2 - h / 2,
               tile_size,
               rdr)
    graphics.agent = agent.sprite

    ball = Ball(0,0,tile_size)

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
local temp = {}
temp.w = tile_size[1]
temp.h = tile_size[2]
local tileset = {}
--grass
tileset[1] = {}
tileset[1].x = graphics.bg_w/2+16*-1
tileset[1].y = 0
tileset[1].w = 16
tileset[1].h = 16
--metal
tileset[2] = {}
tileset[2].x = graphics.bg_w/2
tileset[2].y = 16*5
tileset[2].w = 16
tileset[2].h = 16
--tree
tileset[3] = {}
tileset[3].x = graphics.bg_w/2+16
tileset[3].y = 16*4
tileset[3].w = 16
tileset[3].h = 16
--short grass
tileset[4] = {}
tileset[4].x = graphics.bg_w/2+16*2
tileset[4].y = 0
tileset[4].w = 16
tileset[4].h = 16
--tall grass
tileset[5] = {}
tileset[5].x = graphics.bg_w/2+16
tileset[5].y = 0
tileset[5].w = 16
tileset[5].h = 16
local pressed = {}
local col_tiles = {}
local col_objs = {ball,agent}
local heal_tiles = {}
while running do
	for e in SDL.pollEvent() do
		if e.type == SDL.event.Quit then
			running = false
		elseif e.type == SDL.event.KeyDown then
			--print(string.format("key down: %d -> %s", e.keysym.sym, SDL.getKeyName(e.keysym.sym)))
            local key_name = SDL.getKeyName(e.keysym.sym)
            if  key_name == 'Space' and not pressed[e.keysym.sym] then
                local rem_r,rem_c = get_tile_ind(agent.pos)
                grow_time[rem_r][rem_c] = 0
                if tile_list[rem_r][rem_c] == 1 then
                    tile_list[rem_r][rem_c] = 2
                    col_tiles[(rem_r-1)*tile_size[1]+ rem_c] = get_tile_rect(rem_r,rem_c)

                else
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
    graphics.rdr:clear()
    for r = 1,num_tiles[1] do
        for c=1,num_tiles[2] do
            temp.x = tile_size[1]*(r-1)
            temp.y = tile_size[2]*(c-1)
            graphics.rdr:copy(graphics.bg,tileset[tile_list[r][c]], temp)
        end
    end
    graphics.rdr:copy(graphics.bg, {x=16*22,y=16*10,w=16,h=16}, ball.pos)
    graphics.rdr:copy(graphics.agent, {x=0,y=0,w=32,h=32}, agent.pos)
    graphics.rdr:present()

    agent.pos.x = agent.pos.x + agent.dir[1]
    agent.pos.y = agent.pos.y + agent.dir[2]

    ball.pos.x = ball.pos.x + ball.dir[1]
    ball.pos.y = ball.pos.y + ball.dir[2]
    --handle collisions----------------------------------- 
    --static/dynamic collisions
    for _,tile in pairs(col_tiles) do
        for _,obj in pairs(col_objs) do
            if collide(tile,obj.pos) then
                obj:handle_col({pos = tile,contact_damage = 0})
            end
        end
    end
    --dynamic/dynamic collisions
    for _,obj1 in pairs(col_objs) do
        for _,obj2 in pairs(col_objs) do
            if obj1 ~= obj2 and  collide(obj1.pos,obj2.pos) then
                obj1:handle_col(obj2)
                obj2:handle_col(obj1)
            end
        end
    end
    local kill = {}
    for k,v in pairs(heal_tiles) do
        if collide(agent.pos,v.rect) then
            print('healed!')
            agent.hp = agent.hp + .1
            print(agent.hp)
            table.insert(kill,k)
            tile_list[v.ind[1]][v.ind[2]] = 1
        end
    end
    for i = 1,#kill do
        table.remove(heal_tiles,kill[i])
    end

    if ball.dir[1] > 0 and ball.pos.x > width - ball.pos.w then
        ball.dir[1] = -1
    elseif ball.dir[1] < 0 and ball.pos.x <= 0 then
        ball.dir[1] = 1
    end

    if ball.dir[2] > 0 and ball.pos.y > height - ball.pos.h then
        ball.dir[2] = -1
    elseif ball.dir[2] < 0 and ball.pos.y <= 0 then
        ball.dir[2] = 1
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
	SDL.delay(0)
end
