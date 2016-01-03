require 'gnuplot'
require 'load_image' 
SDL	= require "SDL"
image	= require "SDL.image"
timer = torch.Timer()
local width	=  192
local height	= 108
 win, err = SDL.createWindow {
    title	= "07 - Bouncing bg",
    width	= width,
    height	= height
}
img,ret = image.load('overworld.png')
img2,ret = image.load('pokeback.png')
--rdr, err = SDL.createRenderer(win, -1,SDL.rendererFlags.TargetTexture)

win_surf = win:getSurface()
SDL.setHint('21','1')
--win_surf  = SDL.createRGBSurface(width,height)
soft_rdr = SDL.createSoftwareRenderer(win_surf,-1)
tex, err = soft_rdr:createTextureFromSurface(img)
tex2, err = soft_rdr:createTextureFromSurface(img2)
--rdr:setTarget(tex)
dest = {x=0,y=0,h=10,w=10}
for i=1,1e3 do
    --dest.x = torch.random(width-32)
    --dest.y = torch.random(height-32)
    img:blit(win_surf)
    --soft_rdr:copy(tex,{x=16*4+2,y=16*14+3,h=16,w=16},dest)
    --rdr:copy(tex,{x=0,y=0,h=32,w=32},dest)
    win:updateSurface()
end
--soft_rdr:present()
os.exit()
--rdr:present()
--

--
pic = torch.zeros(height,width)
bytes = win_surf:getPixels()
--print(bytes,#bytes)
timer:reset()
for r=1,height do
    for c=1,width do
        --pic[r][c] = string.byte(win_surf:getRawPixel(c-1,r-1))
        pic[r][c] = string.byte(bytes,(r-1)*(width*4)+(c-1)*4+1)
    end   
end
print(1/timer:time().real)
gnuplot.imagesc(pic)
--]]
SDL.delay(5000)
