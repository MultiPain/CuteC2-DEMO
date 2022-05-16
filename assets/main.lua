require "CuteC2"
require "SceneManager"

sceneManager = SceneManager.new({
	Collisions = CollisionsScene,
	TOI = TOIScene,
	GJK = GJKScene,
})

sceneManager:changeScene("Collisions")
stage:addChild(sceneManager)