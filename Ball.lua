local Ball = torch.class('Ball')
--TODO:deal with spritesheet
function Ball:__init(x,y,tile_size)
    self.pos = {}
    self.pos.w = tile_size[1]
    self.pos.h = tile_size[2]
    self.contact_damage = 1
    self:reset(x,y)
end

function Ball:reset(x,y)
    self.pos.x = x
    self.pos.y = y
    self.dir = torch.ones(2)
end

function Ball:handle_col(oo)
    self.dir:mul(-1)
    self.pos.x = 2*self.pos.x - oo.pos.x
    self.pos.y = 2*self.pos.y - oo.pos.y
end
