require 'load_image'
local agent = {}

agent.pos = {}
agent.max_hp = 10
agent.contact_damage = 0
function agent.init(x,y,tile_size,rdr)
    agent.pos.w = tile_size[1]
    agent.pos.h = tile_size[2]
    agent.reset(x,y)
    --TODO: decouple direction and speed: agent.speed
    
    agent.sprite = load_image("scientist.png",rdr)
end
function agent.reset(x,y)
    agent.pos.x = x
    agent.pos.y = y
    agent.dir = torch.zeros(2)
    agent.hp = agent.max_hp
end

function agent:handle_col(oo)
    agent.pos.x = 2*agent.pos.x - oo.pos.x
    agent.pos.y = 2*agent.pos.y - oo.pos.y
    agent.hp = agent.hp - oo.contact_damage
    print(agent.hp)
end

return agent
