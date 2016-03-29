local HeatSeeker,parent = torch.class('HeatSeeker','Being')
function HeatSeeker:__init(x,y,tile_size,sheet,sheet_pos,enemy)
    sheet_pos = {x=16*8+2,y=16*15+3,h=16,w=16}
    parent.__init(self,x,y,tile_size,sheet,sheet_pos)
    self.enemy = enemy
    self.speed = 200
    self.contact_damage = 3
    self.decay = 10
    self:reset(x,y)
end

function HeatSeeker:handle_col(oo)
    parent.handle_col(self,oo)
    --if oo == self.enemy then
        print('Boom!')
        self.dead = true
    --end
end

function HeatSeeker:handle_movement(dt)
    self.dir[1] = self.enemy.pos.x - self.pos.x
    self.dir[2] = self.enemy.pos.y - self.pos.y
    parent.handle_movement(self,dt)
end

function HeatSeeker:handle_death()
    parent.handle_death(self)
    return true
end
