require "CuteC2"
require "SceneManager"

sceneManager = SceneManager.new({
	Collisions = CollisionsScene,
	TOI = TOIScene,
	GJK = GJKScene,
	Ray = RayScene,
})

sceneManager:changeScene("Ray")
stage:addChild(sceneManager)