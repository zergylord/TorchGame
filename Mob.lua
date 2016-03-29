local Mob,parent = torch.class('Mob','Being')
require 'HeatSeeker'
function Mob:__init(x,y,tile_size,sheet,sheet_pos,enemy)
    parent.__init(self,x,y,tile_size,sheet,sheet_pos)
    self.enemy = enemy
    self.speed = 100
    self.contact_damage = 1
    self.attack_timer = torch.rand(1)[1]
    self.change_movement_timer = torch.rand(1)[1]
    self.seen_enemy = false
    self:reset(x,y)
end
function Mob:handle_movement(dt)
    self.attack_timer = self.attack_timer + dt
    self.change_movement_timer = self.change_movement_timer + dt
    if self.change_movement_timer > 2 then
        self.change_movement_timer = 0
        local enemy_dist = torch.dist(torch.Tensor{self.enemy.pos.x,self.enemy.pos.y},
                    torch.Tensor{self.pos.x,self.pos.y})
        if enemy_dist < 200 then
            self.seen_enemy = true
            print('I sees him!')
        elseif self.seen_enemy and enemy_dist > 400 then
            print('I lost him!')
            self.seen_enemy = false
        end
        if self.seen_enemy then
            self.dir[1] = self.enemy.pos.x - self.pos.x
            self.dir[2] = self.enemy.pos.y - self.pos.y
        else
            self.dir[1] = torch.rand(1):add(-.5)
            self.dir[2] = torch.rand(1):add(-.5)
        end
        self.dir:div(self.dir:norm())
    end


    local obj
    if self.attack_timer > 1 and self.seen_enemy then
        print('attack!')
        obj = HeatSeeker(self.pos.x+self.pos.w*2*self.dir[1],self.pos.y+self.pos.h*2*self.dir[2],tile_size,
                    self.sheet,self.sheet_pos,self.enemy)

        self.attack_timer = 0
    end
    parent.handle_movement(self,dt)
    return obj
end

function Mob:handle_death()
    parent.handle_death(self)
    return false
end
