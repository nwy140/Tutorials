import harfang as hg

hg.LoadPlugins()

plus = hg.GetPlus()
plus.RenderInit(400, 300)

while not plus.IsAppEnded():
	plus.Flip()
	plus.EndFrame()

plus.RenderUninit()