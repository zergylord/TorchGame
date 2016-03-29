local Human,parent = torch.class('Human','Agent')

function Human:__init(x,y,tile_size,cam_width,cam_height)
    self.sheet = 'agent'
    self.sprite ={{x=16*0+2,y=16*0+3,h=16,w=16},
                    {x=16*1+2,y=16*0+3,h=16,w=16},
                    {x=16*2+2,y=16*0+3,h=16,w=16}}
    parent.__init(self,x,y,tile_size,self.sheet,self.sprite,cam_width,cam_height)
end
function Human:build_wall()
    local rem_r,rem_c = get_tile_ind(self.pos)
    grow_time[rem_r][rem_c] = 0
    --if plain dirt, wall
    if tile_list[rem_r][rem_c] == 1 then
        change_tile(2,rem_r,rem_c)
    else --back to dirt
        change_tile(1,rem_r,rem_c)
    end
end
function Human:remove_tile()
    local rem_r,rem_c = get_tile_ind(self.pos)
    local off_r,off_c = 0,0
    if self.heading == 1 then
        off_c = 1
    elseif self.heading == 2 then
        off_c = -1
    elseif self.heading == 3 then
        off_r = -1
    elseif self.heading == 4 then
        off_r = 1
    end
    change_tile(1,math.min(num_tiles[1],rem_r+off_r),rem_c+off_c)
end
function Human:plant_grass()
    local rem_r,rem_c = get_tile_ind(self.pos)
    change_tile(4,rem_r,rem_c)
end
function Human:shoot()
    local obj = Bullet(self.pos.x+self.dir[1]*2,self.pos.y+self.dir[2]*2,tile_size,self.dir)
    return obj
end

