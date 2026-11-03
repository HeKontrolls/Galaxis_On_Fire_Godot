extends RefCounted


static func obsidian_atlas() -> ImageTexture:
	var image := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	var palette := [Color("211d2c"), Color("292234"), Color("322a42"), Color("3e3451")]
	for variant in range(4):
		for y in range(16):
			for x in range(16):
				var facet := posmod(int((x + variant * 3) / 5) * 11 + int((y + variant) / 4) * 7, 4)
				var color: Color = palette[facet]
				if posmod(x + y * 2 + variant * 5, 19) == 0 and y < 12:
					color = Color("645576")
				if posmod(x - y + variant * 3, 23) == 0:
					color = Color("17151f")
				image.set_pixel(variant * 16 + x, y, color)
	return ImageTexture.create_from_image(image)
