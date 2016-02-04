function get_pixels(graphics)
    h,w = graphics.h,graphics.w
    bytes = graphics.surf:getPixels()
    pic = torch.zeros(h,w)
    for r=1,h do
        for c=1,w do
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
function get_tile_rect(r,c)
    local rect= {}
    rect.x = (r-1)*tile_size[1]
    rect.y = (c-1)*tile_size[2]
    rect.w = tile_size[1]
    rect.h = tile_size[2]
    return rect
end
function add_col_tile(row,col,dam,kill)
    local ind = (row-1)*num_tiles[1]+ col
    col_tiles[ind] = {} 
    col_tiles[ind].rect = get_tile_rect(row,col)
    col_tiles[ind].ind = torch.Tensor{row,col}
    col_tiles[ind].killable = kill
    col_tiles[ind].contact_damage = dam
end
--sets up all of the additional effects of a tiles type
--to be called whenever that type has changed
function add_tile_effects(tile_type,row,col)
    grow_time[row][col] = 0
    if tile_type == 1 then
        col_tiles[(row-1)*num_tiles[1]+ col] = nil
    elseif tile_type == 2 then
        add_col_tile(row,col,0,false)
    elseif tile_type == 4 then
        grow_time[row][col] = 1
    elseif tile_type == 5 then
        add_col_tile(row,col,-1,true)
    elseif tile_type == 6 then
        add_col_tile(row,col,1,true)
    end
end

function remove_tile_effects(row,col)
    local tile_type = tile_list[row][col]
    if tile_type == 1 then
    elseif tile_type == 2 then
        col_tiles[(row-1)*num_tiles[1]+ col] = nil
    elseif tile_type == 4 then
        grow_time[row][col] = 0
    elseif tile_type == 5 then
        col_tiles[(row-1)*num_tiles[1]+ col] = nil
    elseif tile_type == 6 then
    end
end

--changes an individual tile *not* a map
--as isn't switching tile_list by reference
function change_tile(tile_type,row,col)
    remove_tile_effects(row,col)
    tile_list[row][col] = tile_type
    add_tile_effects(tile_type,row,col)
end
function load_tilemap(map)
    tile_list = map
    for x = 1,num_tiles[1] do
        for y = 1,num_tiles[2] do
            remove_tile_effects(x,y)
            add_tile_effects(map[x][y],x,y)
        end
    end
end

--region contains:
--tile: a 2D tilemap
--objects: movable objects e.g. agents, balls
function generate_region()
    local region = {}
    --tilemap generate
    region.tile = torch.ones(num_tiles[1],num_tiles[2])
    --trees
    local tile_mask = torch.rand(region.tile:size()):gt(.95)
    region.tile[tile_mask] = 2
    --blight
    tile_mask = torch.rand(region.tile:size()):gt(.8)
    region.tile[tile_mask] = 6
    --movable object generation
    region.objects = {}
    table.insert(region.objects,world.agent)
    --table.insert(region.objects,pokemon)
    for b=1,num_balls do
        local ball = Mob(torch.random(height),torch.random(width),tile_size,'agent',{x=16*7+2,y=16*15+3,h=16,w=16},world.agent)
        table.insert(region.objects,ball)
    end
    --local new_bullet = Bullet(torch.random(height),torch.random(width),tile_size,torch.rand(2))
    --table.insert(region.objects,new_bullet)
    return region
end
function save_world(fn)
    print('saving') 
    local temp_dir = world.agent.dir:clone()
    world.agent:stop()
    torch.save(fn,world)
    world.agent.dir = temp_dir
end
function load_world(fn)
    print('loading')
    world = torch.load(fn)
    local x,y = world.x,world.y
    load_tilemap(world.region[x][y].tile)
    col_objs = world.region[x][y].objects
    camera = world.agent.camera
end
function update_world_map()
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
function change_region(x,y)
    --if not generated, then generate
    if next(world.region[x][y]) == nil then
        world.region[x][y] = generate_region()
    end
    load_tilemap(world.region[x][y].tile)
    col_objs = world.region[x][y].objects
    if has_human then
        update_world_map()
    end
end

function get_tile_ind(rect)
    local x = rect.x+rect.w/2
    local y = rect.y+rect.w/2
    local r = math.floor(x/tile_size[1])+1
    local c = math.floor(y/tile_size[2])+1
    return r,c
end
function collide(r1,r2)
    return r1.x + r1.w > r2.x and
        r1.x < r2.x + r2.w and
        r1.y + r1.h > r2.y and
        r1.y < r2.y + r2.h
end
