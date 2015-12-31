local image	= require "SDL.image"
function load_image(fn,rdr)
	local img, ret = image.load(fn)
	if not img then
		error(err)
	end

	local tex, err = rdr:createTextureFromSurface(img)
	if not tex then
		error(err)
	end
    return tex,img
end
