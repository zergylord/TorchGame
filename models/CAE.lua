require 'nngraph'
require 'optim'
require 'gnuplot'
timer = torch.Timer()
input = nn.Identity()()
conv1 = nn.ReLU()(nn.SpatialConvolutionMM(1,64,6,6,2,2)(input))
conv2 = nn.ReLU()(nn.SpatialConvolutionMM(64,64,6,6,2,2,2,2)(conv1))
conv3 = nn.ReLU()(nn.SpatialConvolutionMM(64,64,6,6,2,2,2,2)(conv2))
num_hid = 64*10*10
hid = nn.ReLU()(nn.Linear(num_hid,num_hid)(nn.View(num_hid)(conv3)))
deconv3 = nn.ReLU()(nn.SpatialFullConvolution(64,64,2,2,2,2)(nn.View(64,10,10)(hid)))
deconv2 = nn.ReLU()(nn.SpatialFullConvolution(64,64,2,2,2,2)(deconv3))
deconv1 = nn.SpatialFullConvolution(64,1,6,6,2,2)(deconv2)
network = nn.gModule({input},{deconv1})
w,dw = network:getParameters()
vid = torch.load('video.t7')
--img = vid[{{10},{},{}}]:double()
img = vid:double()
img = img:reshape(100,1,84,84)
img = (img- img:mean())/128
local mse_crit = nn.MSECriterion()
function opfunc(x)
    if x~= w then
        w:copy(x)
    end
    network:zeroGradParameters()
    output = network:forward(img)
    loss = mse_crit:forward(output,img)
    grad = mse_crit:backward(output,img)
    network:backward(img,grad)
    return loss,dw 
end
--[[
config = {
    learningRate = 1e-1, momentum = .95
}--]]
config = {
    learningRate = 1e-3
}
print(config.learningRate)
cumloss = 0
for i = 1,1e5 do
    x, batchloss = optim.adam(opfunc, w, config)
    cumloss = cumloss + batchloss[1]
    if i %1 == 0 then
        print(i,cumloss,w:norm(),dw:norm(),timer:time().real)
        timer:reset()
        gnuplot.imagesc(output[{10,1,{},{}}])
        --gnuplot.imagesc(img[{1,{},{}}])
        gnuplot.plotflush()
        cumloss = 0
    end
end
