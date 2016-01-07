--Object with health and death
local Being,parent = torch.class('Being','Object')

function Being:__init(x,y,tile_size,sheet,sheet_pos)
    parent.__init(self,x,y,tile_size,sheet,sheet_pos)
    self.max_hp = 10
    self.decay = .1
    self.hp_bar = true
end
function Being:reset(x,y)
    parent.reset(self,x,y)
    self.hp = self.max_hp
    self.dead = false
end
function Being:handle_col(oo)
    parent.handle_col(self,oo)
    self.hp = math.min(self.max_hp,self.hp - oo.contact_damage)
end
function Being:handle_movement(dt)
    parent.handle_movement(self,dt)
    --TODO:seperate logic function
    self.hp = self.hp - self.decay*dt
    if self.hp < 0 then
        self.dead = true
    end
end
local hp_bar_height = 5
function Being:render(graphics,camera)
    parent.render(self,graphics,camera)
    if self.hp_bar then
        local temp = {x=(self.pos.x-camera.x)*graphics.scale,
                    y=(self.pos.y-hp_bar_height-5-camera.y)*graphics.scale,
                    w=(self.hp/self.max_hp)*self.pos.w*graphics.scale,
                    h=(hp_bar_height)*graphics.scale}
        graphics.rdr:fillRect(temp)
    end
end
