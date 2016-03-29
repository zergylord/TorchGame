local Bullet,parent = torch.class('Bullet','Being')
function Bullet:__init(x,y,tile_size,dir)
    self.sheet = 'agent'
    self.sheet_pos = {x=16*7+2,y=16*15+3,h=16,w=16}
    parent.__init(self,x,y,tile_size,self.sheet,self.sheet_pos)
    self:reset(x,y)
end
function Bullet:reset(x,y)
    parent.reset(self,x,y)
    self.dir = torch.rand(2):add(-.5):mul(2)
end
function Bullet:handle_movement(dt)
    parent.handle_movement(self,dt)
end
function Bullet:handle_col(oo)
    parent.handle_col(self,oo)
    print('Bang!')
    self.dead = true
end
function handle_death()
    parent.handle_death(self)
    return true
end
