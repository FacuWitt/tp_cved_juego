class_name SoftPuff
extends RefCounted
## Texturas blandas para partículas: una nube con bordes deshilachados (agua pulverizada, cortinas
## de lluvia) o una gota redonda. Las usan RiverBuilder (rápidos de la M2) y RainGusts (lluvia de la M4).


## Nube (`cloud` = true, bordes con ruido) o gota (redonda y blanda). Blanca: el color lo pone el material.
static func texture(cloud: bool, seed: int = 0) -> ImageTexture:
	var size: int = 128 if cloud else 32
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 0.045
	noise.fractal_octaves = 4
	var c: float = float(size - 1) * 0.5
	for y: int in size:
		for x: int in size:
			var d: float = Vector2(float(x) - c, float(y) - c).length() / c
			var a: float = 1.0 - smoothstep(0.25, 1.0, d)
			if cloud:
				var n: float = noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
				a = clampf(a * (0.35 + n * 1.1) - (1.0 - a) * 0.3, 0.0, 1.0)
				a = smoothstep(0.05, 0.9, a)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)


## Raya de lluvia: más opaca en el medio y que se desvanece en las puntas (a lo largo de la textura).
static func streak() -> GradientTexture2D:
	var g: Gradient = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t: GradientTexture2D = GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0.0, 0.0)
	t.fill_to = Vector2(0.0, 1.0)
	t.width = 4
	t.height = 64
	return t
