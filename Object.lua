local Object = torch.class('Object')

function Object:__init(x,y,tile_size,sheet,sheet_pos)
    self.pos = {}
    self.pos.w = tile_size[1]
    self.pos.h = tile_size[2]
    self.contact_damage = 0
    self.sheet = sheet
    self.sheet_pos = sheet_pos
end

function Object:reset(x,y)
    self.pos.x = x
    self.pos.y = y
    self.dir = torch.zeros(2)
    self.speed = 200
end

function Object:handle_col(oo)
    self.pos.x = 2*self.pos.x - oo.pos.x
    self.pos.y = 2*self.pos.y - oo.pos.y
end

function Object:handle_bounds(width,height)
    if self.pos.x > width - self.pos.w then
        self.pos.x = width - self.pos.w
    elseif self.pos.x < 0 then
        self.pos.x = 0 
    end

    if self.pos.y > height - self.pos.h then
        self.pos.y = height - self.pos.h
    elseif self.pos.y < 0 then
        self.pos.y = 0
    end
end
--]]
function Object:handle_movement(dt)
    local normalize = (self.dir[1]^2 + self.dir[2]^2)^.5
    if normalize > 0 then
    self.pos.x = self.pos.x + (self.dir[1]*self.speed*dt)/normalize
    self.pos.y = self.pos.y + (self.dir[2]*self.speed*dt)/normalize
    end
end

function Object:render(graphics,camera)
    local temp = {x=(self.pos.x-camera.x)*graphics.scale,
                y=(self.pos.y-camera.y)*graphics.scale,
                w=(self.pos.w)*graphics.scale,
                h=(self.pos.h)*graphics.scale}
    graphics.rdr:copy(graphics[self.sheet],self.sheet_pos, temp)
end
    
