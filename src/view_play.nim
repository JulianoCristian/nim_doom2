import strutils

import nimx.context
import nimx.types
import nimx.view
import nimx.window

import rod.animated_image
import rod.component
import rod.component.camera
import rod.node
import rod.rod_types
import rod.viewport

import wad.doomdata

import picture

const VIEWPORT_SIZE* = newSize(320, 200)

type
    GameView* = ref object of SceneView
        gameData: DoomData
        map: Map

    Thing* = ref object of Component  ## Something interactable on map

    Player* = ref object of Thing     ## Player on map

proc newGameView(gameData: DoomData, levelNumber: int = 0): GameView =
    result.new
    result.gameData = gameData
    result.map = gameData.maps[levelNumber]

method init(v: GameView, r: Rect) =
    procCall v.View.init(r)
    v.rootNode = newNode("root")

    let cameraNode = v.rootNode.newChild("camera")
    let camera = cameraNode.component(Camera)
    camera.projectionMode = cpPerspective
    cameraNode.translation.z = 1

    cameraNode.translation.x = VIEWPORT_SIZE.width / 2
    cameraNode.translation.y = VIEWPORT_SIZE.height / 2

    discard v.makeFirstResponder()

    v.setNeedsDisplay()

method draw(v: GameView, r: Rect) =
    procCall v.SceneView.draw(r)

registerComponent[Thing]()
registerComponent[Player]()
