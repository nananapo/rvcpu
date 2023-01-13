ACT_X = 360
ACT_Y = 360

VRAM_X = ACT_X >> 3
VRAM_Y = ACT_Y >> 3
vram = [0] * (VRAM_X * VRAM_Y)

for vindex in range(VRAM_X * VRAM_Y):
	#if vindex % VRAM_X >= VRAM_X / 2:
	if vindex >= VRAM_X * VRAM_Y // 2:
		vram[vindex] = 1
	else:
		vram[vindex] = 0

actual = [[2 for i in range(ACT_X)] for j in range(ACT_Y)]
for act in range(ACT_X * ACT_Y):
	ax = act % ACT_X
	ay = act // ACT_Y
	vx = ax >> 3
	vy = ay >> 3
	vindex = vx + vy * VRAM_X
	actual[ay][ax] = vram[vindex]

for i in range(ACT_Y):
	print(actual[i])