require 'nn'
count_neighbors = nn.SpatialConvolution(1,1,3,3,1,1,1,1)
count_neighbors.weight:zero():add(1)
count_neighbors.bias:zero()
data = torch.rand(1,9,9):gt(.5):double()
print(data,count_neighbors:forward(data))
