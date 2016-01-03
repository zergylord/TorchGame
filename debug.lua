require 'nngraph'
require 'optim'
require 'gnuplot'
timer = torch.Timer()
input = nn.Identity()()
conv1 = nn.ReLU()(nn.SpatialConvolutionMM(1,64,6,6,2,2)(input))
conv2 = nn.ReLU()(nn.SpatialConvolutionMM(64,64,6,6,2,2,2,2)(conv1))
conv3 = nn.ReLU()(nn.SpatialConvolutionMM(64,64,6,6,2,2,2,2)(conv2))
num_hid = 64*10*10
num_fact = 4
enc = nn.ReLU()(nn.Linear(num_hid,num_hid)(nn.View(-1):setNumInputDims(4)(conv3)))
z = nn.Identity()()
num_cont = 4
dec = nn.Linear(num_hid,num_fact)(enc)
--[[
deconv3 = nn.ReLU()(nn.SpatialFullConvolution(64,64,2,2,2,2)(nn.View(64,10,10)(dec)))
deconv2 = nn.ReLU()(nn.SpatialFullConvolution(64,64,2,2,2,2)(deconv3))
deconv1 = nn.SpatialFullConvolution(64,1,6,6,2,2)(deconv2)
--]]
network = nn.gModule({input},{enc})
w,dw = network:getParameters()
vid = torch.load('video.t7')
img = vid:double()
img = img:reshape(100,1,84,84)
img = (img- img:mean())/128

data = img[{{1,99},{},{},{}}]
act = torch.zeros(99,4)

--output = network:forward{data,act}
