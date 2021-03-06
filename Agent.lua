require 'load_image'
local Agent,parent = torch.class('Agent','Being')

function Agent:__init(x,y,tile_size,sheet,sheet_pos,cam_width,cam_height)
    self.sprite = sheet_pos
    parent.__init(self,x,y,tile_size,sheet,self.sprite[1])
    print(tile_size[1]*3/4)
    self.pos.w = tile_size[1]*3/4
    self.pos.h = tile_size[2]*3/4
    self.heading = 1
    self.max_hp = 10
    self.speed = 100
    self.camera = {x=x,y=y,w=cam_width,h=cam_height}
    self:reset(x,y)
    --TODO: decouple direction and speed: self.speed
end
function Agent:reset(x,y)
    parent.reset(self,x,y)
end
--cease movement and actions (used before serializing object(
function Agent:stop()
    self.dir:zero()
end

--used for normal movement. camera slowly tracking player
--YOU MUST OVERIDE THIS, should return new objs, not diffs
function Agent:handle_movement(dt)
    local xdiff,ydiff = parent.handle_movement(self,dt)
    if xdiff ~= 0 or ydiff ~= 0 then
        if math.abs(xdiff) > math.abs(ydiff) then
            if xdiff > 0 then
                self.heading = 4
            else
                self.heading = 3
            end
        else
            if ydiff >= 0 then
                self.heading = 1
            else
                self.heading = 2
            end
        end
    end
    --TODO:seperate logic function
    self.hp = self.hp -.1*dt
    if self.hp < 0 then
        self.dead = true
    end
    alpha = .1
    self.camera.x = self.camera.x*(1-alpha) + alpha*(self.pos.x + self.pos.w/2- self.camera.w/2)
    self.camera.y = self.camera.y*(1-alpha) +alpha*(self.pos.y + self.pos.h/2- self.camera.h/2)
    
end
--teleport yourself plus camera
function Agent:set_position(x,y)
    parent.set_position(self,x,y)
    self.camera.x = self.pos.x + self.pos.w/2- self.camera.w/2
    self.camera.y = self.pos.y + self.pos.h/2- self.camera.h/2
end
--handle camera not going off region
function Agent:handle_bounds(width,height)
    local hit = parent.handle_bounds(self,width,height)
    if self.camera.x < 0 then
        self.camera.x = 0
    elseif self.camera.x > width - self.camera.w then
        self.camera.x = width -self.camera.w
    end
    if self.camera.y < 0 then
        self.camera.y = 0
    elseif self.camera.y > height - self.camera.h then
        self.camera.y = height - self.camera.h
    end
    return hit
end
function Agent:render(graphics,camera)
    self.sheet_pos = self.sprite[self.heading]
    if self.heading == 4 then
        self.flip = 1
        self.sheet_pos = self.sprite[self.heading-1]
    else
        self.flip = 0 
    end
    parent.render(self,graphics,camera)
end
