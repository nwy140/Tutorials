hg = require("harfang")

hg.LoadPlugins()

plus = hg.GetPlus()
plus:RenderInit(400, 300)

while not plus:IsAppEnded() do
	plus:Clear()
	plus:Triangle2D(40, 40, 200, 260, 360, 40, hg.Color.Red, hg.Color.Blue, hg.Color.Green)
	plus:Flip()
	plus:EndFrame()
end

plus:RenderUninit()