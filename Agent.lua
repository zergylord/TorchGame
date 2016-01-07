require 'load_image'
local Agent,parent = torch.class('Agent','Being')

function Agent:__init(x,y,tile_size,sheet,sheet_pos,cam_width,cam_height)
    parent.__init(self,x,y,tile_size,sheet,sheet_pos)
    self.max_hp = 10
    self.camera = {x=x,y=y,w=cam_width,h=cam_height}
    self:reset(x,y)
    --TODO: decouple direction and speed: self.speed
end
function Agent:reset(x,y)
    parent.reset(self,x,y)
end

--used for normal movement. camera slowly tracking player
function Agent:handle_movement(dt)
    parent.handle_movement(self,dt)
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
    parent.render(self,graphics,camera)
end
