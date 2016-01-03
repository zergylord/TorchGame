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
num_hid = 500
num_fact = 1000
enc = nn.ReLU()(nn.Linear(num_conv,num_hid)(nn.View(num_conv)(conv3)))
num_cont = 2
--infer z
num_z_hid = num_hid/10
inputPrime = nn.Identity()()
-- split params
z_conv1 = nn.ReLU()(nn.SpatialConvolutionMM(num_hist+2,64,6,6,2,2)(inputPrime))
z_conv2 = nn.ReLU()(nn.SpatialConvolutionMM(64,64,6,6,2,2,2,2)(z_conv1))
z_conv3 = nn.ReLU()(nn.SpatialConvolutionMM(64,64,6,6,2,2,2,2)(z_conv2))
z =
    nn.Tanh()(nn.Linear(num_z_hid,num_cont)
    (nn.ReLU()(nn.Linear(num_conv,num_z_hid)(nn.View(num_conv)(z_conv3))))
    )
--]]
--[[share params
prime_conv1 = nn.ReLU()(nn.SpatialConvolutionMM(1,64,6,6,2,2)(inputPrime))
prime_conv2 = nn.ReLU()(nn.SpatialConvolutionMM(64,64,6,6,2,2,2,2)(prime_conv1))
prime_conv3 = nn.ReLU()(nn.SpatialConvolutionMM(64,64,6,6,2,2,2,2)(prime_conv2))
prime_enc = nn.ReLU()(nn.Linear(num_conv,num_hid)(nn.View(num_conv)(prime_conv3)))
z =
    nn.Tanh()(nn.Linear(num_z_hid,num_cont)
    (nn.ReLU()(nn.Linear(num_hid*2,num_z_hid)(nn.JoinTable(2){enc,prime_enc})))
    )
    --]]
dec = nn.Linear(num_fact,num_conv)(nn.CMulTable(){nn.Linear(num_hid,num_fact)(enc),nn.Linear(num_cont,num_fact)(z)})
deconv3 = nn.ReLU()(nn.SpatialFullConvolution(64,64,2,2,2,2)(nn.View(64,10,10)(dec)))
deconv2 = nn.ReLU()(nn.SpatialFullConvolution(64,64,2,2,2,2)(deconv3))
deconv1 = nn.SpatialFullConvolution(64,1,6,6,2,2)(deconv2)
network = nn.gModule({input,inputPrime},{deconv1})
w,dw = network:getParameters()
print(w:size())
vid,act = unpack(torch.load('video.t7'))
img = vid:double()
num_samples = img:size(1)
img = (img- img:mean())/128
num_data = num_samples-1-num_hist
data = torch.Tensor(num_data,num_hist+1,84,84)
z_data = torch.Tensor(num_data,num_hist+2,84,84)
for i=1,num_data do
    data[i]= img[{{i,i+num_hist},{},{}}]
    z_data[i]= img[{{i,i+num_hist+1},{},{}}]
end
act = act[{{num_hist+1,-2},{}}]
img = img:reshape(num_samples,1,84,84)
target = img[{{num_hist+1+1,-1},{},{},{}}]
local mse_crit = nn.MSECriterion()
mb_size = 100
mb_data = torch.zeros(mb_size,num_hist+1,84,84)
mb_z_data = torch.zeros(mb_size,num_hist+2,84,84)
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
        mb_z_data[i] = z_data[mb_ind[i]] 
        mb_act[i] = act[mb_ind[i]]
        mb_target[i] = target[mb_ind[i]]
    end
    output = network:forward{mb_data,mb_z_data}--mb_target}
    loss = mse_crit:forward(output,mb_target)
    grad = mse_crit:backward(output,mb_target)
    network:backward({mb_data,mb_z_data},grad) --mb_target
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
