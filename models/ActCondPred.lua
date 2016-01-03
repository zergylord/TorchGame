require 'nngraph'
require 'optim'
require 'gnuplot'
timer = torch.Timer()
input = nn.Identity()()
num_hist = 3
conv1 = nn.ReLU()(nn.SpatialConvolutionMM(num_hist+1,64,6,6,2,2)(input))
conv2 = nn.ReLU()(nn.SpatialConvolutionMM(64,64,6,6,2,2,2,2)(conv1))
conv3 = nn.ReLU()(nn.SpatialConvolutionMM(64,64,6,6,2,2,2,2)(conv2))
num_conv = 64*10*10
num_hid = 1024
num_fact = 10
enc = nn.ReLU()(nn.Linear(num_conv,num_hid)(nn.View(num_conv)(conv3)))
z = nn.Identity()()
num_cont = 2
dec = nn.Linear(num_fact,num_conv)(nn.CMulTable(){nn.Linear(num_hid,num_fact)(enc),nn.Linear(num_cont,num_fact)(z)})
deconv3 = nn.ReLU()(nn.SpatialFullConvolution(64,64,2,2,2,2)(nn.View(64,10,10)(dec)))
deconv2 = nn.ReLU()(nn.SpatialFullConvolution(64,64,2,2,2,2)(deconv3))
deconv1 = nn.SpatialFullConvolution(64,1,6,6,2,2)(deconv2)
network = nn.gModule({input,z},{deconv1})
w,dw = network:getParameters()
print(w:size())
vid,act = unpack(torch.load('video.t7'))
img = vid:double()
num_samples = img:size(1)
img = (img- img:mean())/128
num_data = num_samples-1-num_hist
data = torch.Tensor(num_data,num_hist+1,84,84)
for i=1,num_data do
    data[{{i},{},{},{}}]= img[{{i,i+num_hist},{},{}}]
end
act = act[{{num_hist+1,-2},{}}]
img = img:reshape(num_samples,1,84,84)
target = img[{{num_hist+1+1,-1},{},{},{}}]
local mse_crit = nn.MSECriterion()
mb_size = 100
mb_data = torch.zeros(mb_size,num_hist+1,84,84)
mb_act = torch.zeros(mb_size,2)
mb_target = torch.zeros(mb_size,1,84,84)
function opfunc(x)
    if x~= w then
        w:copy(x)
    end
    network:zeroGradParameters()
    mb_ind = torch.randperm(num_data)
    for i = 1,mb_size do
        mb_data[i] = data[mb_ind[i]] 
        mb_act[i] = act[mb_ind[i]]
        mb_target[i] = target[mb_ind[i]]
    end
    output = network:forward{mb_data,mb_act}
    loss = mse_crit:forward(output,mb_target)
    grad = mse_crit:backward(output,mb_target)
    network:backward({mb_data,mb_act},grad)
    return loss,dw 
end
config = {
    learningRate = 1e-3
}
print(config.learningRate)
cumloss = 0
for i = 1,1e5 do
    x, batchloss = optim.adam(opfunc, w, config)
    cumloss = cumloss + batchloss[1]
    if i %1e1 == 0 then
        print(i,cumloss,w:norm(),dw:norm(),timer:time().real)
        timer:reset()
        ind = torch.random(mb_size)
        gnuplot.imagesc(output[{ind,1,{},{}}])
        gnuplot.plotflush()
        cumloss = 0
    end
end
