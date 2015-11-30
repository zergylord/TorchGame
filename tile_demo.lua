local SDL	= require "SDL"
local image	= require "SDL.image"

local running	= true
local graphics	= { }
local agent_pos	= { }
local ball_pos	= { }
local agent_dir	= torch.zeros(2)
local ball_dir	= torch.ones(2)
local width	= 640
local height	= 480
local num_tiles = {20,20}
local tile_size = {width/num_tiles[1],height/num_tiles[2]}
local function load_image(fn)
	local img, ret = image.load(fn)
	if not img then
		error(err)
	end

	local tex, err = rdr:createTextureFromSurface(img)
	if not tex then
		error(err)
	end
    return tex
end
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
    local bg = load_image("pokeback.png")
    local guy = load_image("scientist.png")

	-- Store in global graphics
	graphics.win	= win
	graphics.rdr	= rdr
	graphics.bg	= bg
    graphics.agent = guy

	-- Get the size of the bg
	local f, a, w, h = bg:query()
    graphics.bg_w = w
    graphics.bg_h = h


	agent_pos.x = width / 2 - w / 2
	agent_pos.y = height / 2 - h / 2
	agent_pos.w = tile_size[1]
	agent_pos.h = tile_size[2]

	ball_pos.x = 0
	ball_pos.y = 0
	ball_pos.w = tile_size[1]
	ball_pos.h = tile_size[2]

    tile_list = torch.ones(num_tiles[1],num_tiles[2])
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
local function handle_ball_collide(rect)
    if collide(ball_pos,rect) then
        ball_dir:mul(-1)
    end
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
local pressed = {}
local col_tiles = {}
while running do
	for e in SDL.pollEvent() do
		if e.type == SDL.event.Quit then
			running = false
		elseif e.type == SDL.event.KeyDown then
            print('down')
			--print(string.format("key down: %d -> %s", e.keysym.sym, SDL.getKeyName(e.keysym.sym)))
            local key_name = SDL.getKeyName(e.keysym.sym)
            if  key_name == 'Space' and not pressed[e.keysym.sym] then
                local rem_r,rem_c = get_tile_ind(agent_pos)
                if tile_list[rem_r][rem_c] == 1 then
                    tile_list[rem_r][rem_c] = 2
                    col_tiles[(rem_r-1)*tile_size[1]+ rem_c] = get_tile_rect(rem_r,rem_c)

                else
                    tile_list[rem_r][rem_c] = 1
                    col_tiles[(rem_r-1)*tile_size[1]+rem_c] = nil
                end
            elseif key_name == 'W'and not pressed[e.keysym.sym] then
                agent_dir[2] = agent_dir[2] -1
            elseif key_name == 'A'and not pressed[e.keysym.sym] then
                agent_dir[1] = agent_dir[1] -1
            elseif key_name == 'S' and not pressed[e.keysym.sym] then
                agent_dir[2] = agent_dir[2] + 1
            elseif key_name == 'D' and not pressed[e.keysym.sym] then
                agent_dir[1] = agent_dir[1] + 1
            elseif key_name == 'Escape' and not pressed[e.keysym.sym] then
                running = false
            end
            pressed[e.keysym.sym] = true
        elseif e.type == SDL.event.KeyUp then
            print('up')
            local key_name = SDL.getKeyName(e.keysym.sym)
            if key_name == 'W' then
                agent_dir[2] = agent_dir[2] +1
            elseif key_name == 'A' then
                agent_dir[1] = agent_dir[1] +1
            elseif key_name == 'S' then
                agent_dir[2] = agent_dir[2] - 1
            elseif key_name == 'D'  then
                agent_dir[1] = agent_dir[1] - 1
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
    graphics.rdr:copy(graphics.bg, {x=16*22,y=16*10,w=16,h=16}, ball_pos)
    graphics.rdr:copy(graphics.agent, {x=0,y=0,w=32,h=32}, agent_pos)
    graphics.rdr:present()

    agent_pos.x = agent_pos.x + agent_dir[1]
    agent_pos.y = agent_pos.y + agent_dir[2]

    ball_pos.x = ball_pos.x + ball_dir[1]
    ball_pos.y = ball_pos.y + ball_dir[2]
    
    for k,v in pairs(col_tiles) do
        handle_ball_collide(v)
    end
    handle_ball_collide(agent_pos)

    if ball_dir[1] > 0 and ball_pos.x > width - ball_pos.w then
        ball_dir[1] = -1
    elseif ball_dir[1] < 0 and ball_pos.x <= 0 then
        ball_dir[1] = 1
    end

    if ball_dir[2] > 0 and ball_pos.y > height - ball_pos.h then
        ball_dir[2] = -1
    elseif ball_dir[2] < 0 and ball_pos.y <= 0 then
        ball_dir[2] = 1
    end

	SDL.delay(0)
end
