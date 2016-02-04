require 'load_image' 
require 'Object'
require 'Being'
require 'Ball'
require 'Bot'
require 'Mob'
require 'Bullet'
require 'Human'
require 'HeatSeeker'
SDL	= require "SDL"
image	= require "SDL.image"
require 'Agent'
require 'gnuplot'
require 'nn'
require 'util.util'

has_human = true
has_bot = true
has_minimap = true
num_balls = 5


local running	= true
disp = { }
width	=  1920
height	= 1080
cam_width,cam_height = 336,336
--TODO: support arbitary num of tiles per region
num_tiles = {80,45}
tile_size = {width/num_tiles[1],height/num_tiles[2]}
obj_size = {tile_size[1]/2,tile_size[2]/2}
frame_timer = torch.Timer()
blight_timer = torch.Timer()
fps = 20
dt = 1/fps

count_neighbors = nn.SpatialConvolution(1,1,3,3,1,1,1,1)
--2 nearest
--count_neighbors = nn.SpatialConvolution(1,1,5,5,1,1,2,2)
count_neighbors.weight:zero():add(1)
count_neighbors.bias:zero()
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
    col_tiles = {}


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
        world.agent = Human(width / 2 - bg_w / 2,
                   height / 2 - bg_h / 2,
                   tile_size,cam_width,cam_height)
        camera = world.agent.camera
    end
    if has_bot then
        bot.surf = bot.win_surf or SDL.createRGBSurface(bot.w,bot.h) 
        bot.rdr, err = SDL.createSoftwareRenderer(bot.surf, -1)
        bot.agent = load_image("res/overworld.png",bot.rdr)
        bot.bg = load_image("res/pokeback.png",bot.rdr)
        local f, a, w, h = bot.bg:query()
        bg_w = w
        bg_h = h
        world.pokemon = Bot(width / 2 - bg_w / 2,
                   height / 2 - bg_h / 2,
                   tile_size,
                   'agent',
                   {{x=16*4+2,y=16*14+3,h=16,w=16},
                   {x=16*5+2,y=16*14+3,h=16,w=16},
                   {x=16*6+2,y=16*14+3,h=16,w=16}},
                   cam_width,cam_height)
        world.pokemon.record = not has_human
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
    --blight
    tileset[6] = {}
    tileset[6].x = 16*8
    tileset[6].y = 0
    tileset[6].w = 16
    tileset[6].h = 16



    tile_list = torch.ones(num_tiles[1],num_tiles[2])
    grow_time = torch.zeros(num_tiles[1],num_tiles[2])


    change_region(world.x,world.y)
    table.insert(col_objs,world.pokemon)
    

end
initialize()
local pressed = {}
while running do
    frame_timer:reset()
	for e in SDL.pollEvent() do
		if e.type == SDL.event.Quit then
			running = false
		elseif e.type == SDL.event.KeyDown then
			--print(string.format("key down: %d -> %s", e.keysym.sym, SDL.getKeyName(e.keysym.sym)))
            local key_name = SDL.getKeyName(e.keysym.sym)
            --TODO:encapsulate ability in agent subclass
            if  key_name == 'Space' and not pressed[e.keysym.sym] then
                world.agent:build_wall()
            elseif key_name == 'P' and not pressed[e.keysym.sym] then
                world.agent:plant_grass()
            elseif key_name == 'L' and not pressed[e.keysym.sym] then
                world.agent:remove_tile()
            elseif key_name == 'O' and not pressed[e.keysym.sym] then
                table.insert(col_objs,world.agent:shoot())
            elseif key_name == 'W'and not pressed[e.keysym.sym] then
                world.agent.dir[2] = world.agent.dir[2] -1
            elseif key_name == 'A'and not pressed[e.keysym.sym] then
                world.agent.dir[1] = world.agent.dir[1] -1
            elseif key_name == 'S' and not pressed[e.keysym.sym] then
                world.agent.dir[2] = world.agent.dir[2] + 1
            elseif key_name == 'D' and not pressed[e.keysym.sym] then
                world.agent.dir[1] = world.agent.dir[1] + 1
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
            elseif key_name == '[' and not pressed[e.keysym.sym] then
                print('saving')
                save_world('foo')
            elseif key_name == ']' and not pressed[e.keysym.sym] then
                print('loading')
                load_world('foo')
            end
            pressed[e.keysym.sym] = true
        elseif e.type == SDL.event.KeyUp then
            local key_name = SDL.getKeyName(e.keysym.sym)
            if key_name == 'W' then
                world.agent.dir[2] = world.agent.dir[2] +1
            elseif key_name == 'A' then
                world.agent.dir[1] = world.agent.dir[1] +1
            elseif key_name == 'S' then
                world.agent.dir[2] = world.agent.dir[2] - 1
            elseif key_name == 'D'  then
                world.agent.dir[1] = world.agent.dir[1] - 1
            end
            pressed[e.keysym.sym] = false
		end
	end
    if has_bot then
        if bot.timer:time().real > (1/fps)*2 then
            bot.timer:reset()
                
            render(bot,world.pokemon.camera)
            if not has_human then
                pic = get_pixels(bot)
                world.pokemon:forward(pic)
            else
                world.pokemon:forward()
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
                mm.rdr:drawRect{x= camera.x*mm.scale,
                                y= camera.y*mm.scale,
                                w= camera.w*mm.scale,
                                h= camera.h*mm.scale}
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
    local kill_obj = {}
    local kill_tile = {}
    local birth_obj = {}
    for ko,obj in pairs(col_objs) do
        if obj.dead then
            if obj:handle_death() then
                table.insert(kill_obj,ko)
            end
            --obj:reset(torch.random(height),torch.random(width))
        end
        --movement 
        local new_obj = obj:handle_movement(dt)
        if new_obj then
            table.insert(birth_obj,new_obj)
        end
        --static/dynamic collisions
        --TODO:unify tiles
        for k,tile in pairs(col_tiles) do
            if collide(tile.rect,obj.pos) then
                obj:handle_col({pos = tile.rect,contact_damage = tile.contact_damage})
                if tile.killable then
                    table.insert(kill_tile,k)
                    change_tile(1,tile.ind[1],tile.ind[2])
                end
            end
        end
        --dynamic/dynamic collisions
        for _,obj2 in pairs(col_objs) do
            --NOTE: collisions stop instantly, or double collision handling happpens!
            if obj ~= obj2 and  collide(obj.pos,obj2.pos) then
                obj:handle_col(obj2)
                obj2:handle_col(obj)
            end
        end
        --boundary collisions
        local hit = obj:handle_bounds(width,height)
        --region change on boundary hits
        if obj == world.agent and hit:ne(0):any() then 
            if hit[1] == -1 then
                world.x = world.x+hit[1]
                if world.x < 1 then
                    world.x = 1
                else
                    world.agent:set_position(width-world.agent.pos.w*2,world.agent.pos.y)
                end
            elseif hit[1] == 1 then
                world.x = world.x+hit[1]
                if world.x > world.w then
                    world.x = world.w
                else
                    world.agent:set_position(world.agent.pos.w*2,world.agent.pos.y)
                end
            elseif hit[2] == -1 then
                world.y = world.y+hit[2]
                if world.y < 1 then
                    world.y = 1
                else
                    world.agent:set_position(world.agent.pos.x,world.agent.pos.h*2)
                end
            elseif hit[2] == 1 then
                world.y = world.y+hit[2]
                if world.y > world.h then
                    world.y = world.h
                else
                    world.agent:set_position(world.agent.pos.x,height-world.agent.pos.h*2)
                end
            end

            change_region(world.x,world.y)
        end
    end
    --remove dead tiles
    for i = 1,#kill_tile do
        table.remove(col_tiles,kill_tile[i])
    end
    for i = 1,#kill_obj do
        table.remove(col_objs,kill_obj[i])
    end
    for _,o in pairs(birth_obj) do
        table.insert(col_objs,o)
    end
    --heal tile logic----------------
    local grow_mask = grow_time:gt(0)
    grow_time[grow_mask] = grow_time[grow_mask] + dt
    local fully_grown = grow_time:gt(10)
    local num_grown = fully_grown:sum()
    if num_grown  > 0 then
        local inds = fully_grown:nonzero()
        for i= 1,num_grown do
            change_tile(5,inds[i][1],inds[i][2])
        end
    end
    --blight tile logic---------------
    if blight_timer:time().real > 50*(1/fps) then
        blight_timer:reset()
        --update 1/25th
        update_div = 5
        local updated_ind = {}
        updated_ind[1] = torch.random(num_tiles[1] - num_tiles[1]/update_div+1)
        updated_ind[2] = torch.random(num_tiles[2] - num_tiles[2]/update_div+1)
        local updated_tiles = tile_list[{{updated_ind[1],updated_ind[1]+num_tiles[1]/update_div-1},
                                        {updated_ind[2],updated_ind[2]+num_tiles[2]/update_div-1}}]
        local blighted = updated_tiles:reshape(1,num_tiles[1]/update_div,num_tiles[2]/update_div):eq(6):double()
        --update everything
        --local blighted = tile_list:reshape(1,num_tiles[1],num_tiles[2]):eq(6):double()
        
        local not_blighted = blighted:eq(0)
        local blight_counts = count_neighbors:forward(blighted)
        --blighted and few (less than 2) neighbors, kill
        local mask = blight_counts:lt(2):cmul(blighted:byte())[{1,{},{}}]
        local inds = mask:nonzero()
        for i=1,mask:sum() do
            change_tile(1,updated_ind[1]-1+inds[i][1],updated_ind[2]-1+inds[i][2])
        end
        --blighted and many (more than 3) neighbors, kill
        mask = blight_counts:gt(3):cmul(blighted:byte())[{1,{},{}}]
        inds = mask:nonzero()
        for i=1,mask:sum() do
            change_tile(1,updated_ind[1]-1+inds[i][1],updated_ind[2]-1+inds[i][2])
        end
        --not blighted and 3 neighbors, become blight
        mask = blight_counts:eq(3):cmul(not_blighted)[{1,{},{}}]
        inds = mask:nonzero()
        for i=1,mask:sum() do
            change_tile(6,updated_ind[1]-1+inds[i][1],updated_ind[2]-1+inds[i][2])
        end

    end
    --]]--------------------------------
    


    local extra_time = (1/fps - frame_timer:time().real)*1000
    if extra_time > 0 then
	   SDL.delay(extra_time)
    else
        --print('lagging by:',-1/(extra_time/1000),' fps')
        print('fps:',math.ceil(1 / frame_timer:time().real))
    end
end
