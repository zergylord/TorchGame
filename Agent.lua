require 'load_image'
local Agent,parent = torch.class('Agent','Object')

function Agent:__init(x,y,tile_size,sheet,sheet_pos,cam_width,cam_height)
    parent.__init(self,x,y,tile_size,sheet,sheet_pos)
    self.max_hp = 10
    self:reset(x,y)
    self.camera = {x=x,y=y,w=cam_width,h=cam_height}
    --TODO: decouple direction and speed: self.speed
end
function Agent:reset(x,y)
    parent.reset(self,x,y)
    self.hp = self.max_hp
end

function Agent:handle_col(oo)
    self.pos.x = 2*self.pos.x - oo.pos.x
    self.pos.y = 2*self.pos.y - oo.pos.y
    self.hp = self.hp - oo.contact_damage
end
function Agent:handle_movement(dt)
    parent.handle_movement(self,dt)
    alpha = .1
    self.camera.x = self.camera.x*(1-alpha) + alpha*(self.pos.x + self.pos.w/2- self.camera.w/2)
    self.camera.y = self.camera.y*(1-alpha) +alpha*(self.pos.y + self.pos.h/2- self.camera.h/2)
end
function Agent:handle_bounds(width,height)
    parent.handle_bounds(self,width,height)
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
end