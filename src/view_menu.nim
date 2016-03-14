import nimx.button
import nimx.context
import nimx.font
import nimx.image
import nimx.types
import nimx.view
import nimx.window

import rod.rod_types
import rod.node
import rod.viewport

import rod.component
import rod.component.camera
import rod.component.sprite
import rod.edit_view

import tables

import picture

const VIEWPORT_SIZE* = newSize(320, 200)

import wad.doomdata

type MenuView* = ref object of SceneView
    img*: Image
    imgpos*: Rect
    gameData: DoomData

proc newMenuView*(r: Rect, gameData: DoomData): MenuView =
    result.new
    result.gameData = gameData

    let doomPic = result.gameData.pictures["TITLEPIC"]
    let img = imageWithDoomPicture(doomPic, result.gameData.palettes[0])
    result.img = img
    result.imgpos = newRect(doomPic.leftOffset.Coord, doomPic.topOffset.Coord, doomPic.width.Coord, doomPic.height.Coord)

    result.init(r)

method init(v: MenuView, r: Rect) =

    procCall v.View.init(r)
    v.rootNode = newNode("root")

    let cameraNode = v.rootNode.newChild("camera")
    let camera = cameraNode.component(Camera)
    cameraNode.translation.z = 1

    cameraNode.translation.x = VIEWPORT_SIZE.width / 2
    cameraNode.translation.y = VIEWPORT_SIZE.height / 2
    camera.manualGetProjectionMatrix = proc(bounds: Rect, mat: var Matrix4) =
        let logicalWidth = bounds.width / (bounds.height / VIEWPORT_SIZE.height)
        mat.ortho(-logicalWidth / 2, logicalWidth / 2, VIEWPORT_SIZE.height / 2, -VIEWPORT_SIZE.height / 2, camera.zNear, camera.zFar)

    let back = v.rootNode.newChild("background")
    let backs = back.component(Sprite)
    backs.image = v.img

    v.setNeedsDisplay()

method draw(v: MenuView, r: Rect) =
    procCall v.SceneView.draw(r)
