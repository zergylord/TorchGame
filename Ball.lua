local Ball,parent = torch.class('Ball','Object')
function Ball:__init(x,y,tile_size,sheet,sheet_pos)
    parent.__init(self,x,y,tile_size,sheet,sheet_pos)
    self.contact_damage = 1
    self:reset(x,y)
end
function Ball:reset(x,y)
    parent.reset(self,x,y)
    self.dir = torch.ones(2)
end

function Ball:handle_col(oo)
    parent.handle_col(self,oo)
    self.dir:mul(-1)
end
function Ball:handle_bounds(width,height)
    if self.dir[1] > 0 and self.pos.x > width - self.pos.w then
        self.dir[1] = -1
    elseif self.dir[1] < 0 and self.pos.x <= 0 then
        self.dir[1] = 1
    end

    if self.dir[2] > 0 and self.pos.y > height - self.pos.h then
        self.dir[2] = -1
    elseif self.dir[2] < 0 and self.pos.y <= 0 then
        self.dir[2] = 1
    end
end
