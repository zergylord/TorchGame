require 'Agent'
local Bot,parent = torch.class('Bot','Agent')

--setup network, given input and action spaces
function Bot:__init(x,y,tile_size,sheet,sheet_pos,cam_width,cam_height)
    parent.__init(self,x,y,tile_size,sheet,sheet_pos,cam_width,cam_height)
    self.step = 1
end
num_frames = 1e3
frames = torch.ByteTensor(num_frames,84,84)
actions = torch.Tensor(num_frames,2)
function Bot:forward(pic)
    frames[self.step]:copy(pic)
    if self.step % 10 == 1 then
        self.dir[1] = torch.random(3)-2
        self.dir[2] = torch.random(3)-2
    end
    actions[self.step]:copy(self.dir)
    self.step = self.step +1
    if self.step > num_frames then
        torch.save('video.t7',{frames,actions})
        os.exit()
    end
end

function Bot:backward(r)

end
