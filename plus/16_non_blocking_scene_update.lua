--[[
This tutorial displays two scene overlays:

- The background scene intentionally updates very slowly (it sleeps for 500ms).
- The foreground scene displays a spinning 3d cube as fast as it can.

Each scene is rendered to a different texture at a different rate. Both output
textures are drawn on top of each other to the screen as fast as possible.

Note that despite blocking Harfang's Lua VM the background scene does not block
rendering of the foreground scene and the main Lua script execution.
]]--

hg = require("harfang")

hg.LoadPlugins()

plus = hg.GetPlus()
hg.MountFileDriver(hg.StdFileDriver("_data/"), "@data/")

width, height = 640, 480

plus = hg.GetPlus()

plus:CreateWorkers() -- try disabling the workers so that the background scene will block this script execution and the fast scene update
plus:RenderInit(width, height)

renderer = plus:GetRendererAsync()

function create_slow_scene()
	scn = plus:NewScene()

	plus:AddCamera(scn, hg.Matrix4.TranslationMatrix(hg.Vector3(0, 0, -10)))
	plus:AddLight(scn, hg.Matrix4.RotationMatrix(hg.Vector3(0.6, -0.4, 0)), hg.LightModelLinear, 100, false)

	cube = plus:AddCube(scn, hg.Matrix4.Identity, 5, 1, 1)
	cube:AddComponent(hg.LogicScript("@data/spin_and_sleep.lua"))

	return scn
end

function update_slow_scene()
	while not plus:IsAppEnded() do
		renderer:SetRenderTarget(rtt_slow)

		scn_slow:Update(dt)
		while not scn_slow:WaitUpdate(false) do
			coroutine.yield() -- yield as long as the scene update is not complete
		end

		scn_slow:Commit()
		while not scn_slow:WaitCommit(false) do
			coroutine.yield() -- yield as long as the scene commit is not complete
		end

		coroutine.yield()
	end
end

function create_fast_scene()
	scn = plus:NewScene()

	plus:AddEnvironment(scn, hg.Color.Transparent, hg.Color.Black) -- clear color to transparent
	plus:AddCamera(scn, hg.Matrix4.TranslationMatrix(hg.Vector3(0, 0, -10)))
	plus:AddLight(scn, hg.Matrix4.TranslationMatrix(hg.Vector3(6, 4, -6)))

	cube = plus:AddCube(scn)
	cube:AddComponent(hg.LogicScript("@data/spin.lua"))

	return scn
end

function update_fast_scene()
	renderer:SetRenderTarget(rtt_fast)

	scn_fast:Update(dt)
	scn_fast:WaitUpdate()
	scn_fast:Commit()
	scn_fast:WaitCommit()
end

function create_scene_render_target(w, h)
	tex = renderer:NewTexture()
	renderer:CreateTexture(tex, w, h)

	rtt = renderer:NewRenderTarget()
	renderer:CreateRenderTarget(rtt)
	renderer:SetRenderTargetColorTexture(rtt, tex)

	return rtt, tex
end

-- create a render target for each scene
rtt_slow, tex_slow = create_scene_render_target(width, height)
rtt_fast, tex_fast = create_scene_render_target(width, height)

-- create a slow scene and a fast scene
scn_slow = create_slow_scene()
scn_fast = create_fast_scene()

-- start the slow scene coroutine
update_slow_scene_co = coroutine.create(update_slow_scene)

plus:SetDepthTest2D(false) -- both scenes will be rendered through the 2D system as fullscreen texture

while not plus:IsAppEnded() do
	dt = plus:UpdateClock()

	-- update the slow scene, the generator will return while Harfang works
	coroutine.resume(update_slow_scene_co)

	-- update the fast scene
	update_fast_scene()

	-- composite the two scene output to screen
	renderer:ClearRenderTarget()

	-- render the slow scene output
	plus:Texture2D(0, 0, 1, tex_slow, hg.Color.White, false, true)

	-- composite the fast output using alpha blending
	plus:SetBlend2D(hg.BlendAlpha)
	plus:Texture2D(0, 0, 1, tex_fast, hg.Color.White, false, true)

	-- restore blend mode
	plus:SetBlend2D(hg.BlendOpaque)

	plus:Flip()
	plus:EndFrame()
end

while coroutine.status(update_slow_scene_co) ~= "dead" do
	coroutine.resume(update_slow_scene_co)
end

plus:RenderUninit()