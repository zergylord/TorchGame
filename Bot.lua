require 'Agent'
local Bot,parent = torch.class('Bot','Agent')

--setup network, given input and action spaces
function Bot:__init(x,y,tile_size,sheet,sheet_pos,cam_width,cam_height)
    parent.__init(self,x,y,tile_size,sheet,sheet_pos,cam_width,cam_height)
    self.step = 0
    self.total_step = 0
    self.record = false
end
num_frames = 1e2
frames = torch.ByteTensor(num_frames,84,84)
actions = torch.Tensor(num_frames,2)
function Bot:forward(pic)
    self.step = self.step +1
    if self.step % 10 == 1 then
        self.dir[1] = torch.random(3)-2
        self.dir[2] = torch.random(3)-2
    end
    if self.record then
        actions[self.step]:copy(self.dir)
        frames[self.step]:copy(pic)
        if self.step >= num_frames then
            self.total_step = self.total_step + self.step
            if self.record then
                torch.save('data/video' .. self.total_step .. '.t7' ,{frames,actions})
            end
            self.step = 0
        end
    end
end

function Bot:backward(r)

end
