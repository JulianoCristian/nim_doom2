import strutils

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

import rod.animated_image
import rod.component
import rod.component.camera
import rod.component.sprite
import rod.edit_view

import tables

import picture

const VIEWPORT_SIZE* = newSize(320, 200)

import wad.doomdata

type MenuItem = ref object
    pic: string
    selected: bool
    subMenu: seq[MenuItem]

proc newMenuItem(pic: string, subMenu: seq[MenuItem], selected: bool = false): MenuItem =
    result.new
    result.pic = pic
    result.selected = selected
    result.subMenu = subMenu

type MenuView* = ref object of SceneView
    mainMenu*: seq[MenuItem]
    img*: Image
    imgpos*: Rect
    gameData: DoomData
    cursor*: Node

proc newMenuView*(r: Rect, gameData: DoomData): MenuView =
    result.new
    result.gameData = gameData

    result.mainMenu = @[
        newMenuItem("M_NGAME",  @[], true),
        newMenuItem("M_OPTION", @[]),
        newMenuItem("M_LOADG",  @[]),
        newMenuItem("M_SAVEG",  @[]),
        newMenuItem("M_QUITG",  @[])
    ]

proc createDoomMenu*(v: MenuView, n: Node, rootItem: MenuItem = nil): Node =
    result = n.newChild("Menu")
    var y: Coord = 72
    if rootItem.isNil:
        for item in v.mainMenu:
            let itemNode = result.newChild(item.pic)
            let itemImage = imageWithDoomPicture(v.gameData.pictures[item.pic], v.gameData.palettes[0])
            itemNode.translation = newVector3(VIEWPORT_SIZE.width / 2 - 63, y, 0)
            y += itemImage.size.height.Coord + 1
            let itemSprite = itemNode.component(Sprite)
            itemSprite.image = itemImage

            if item.selected == true:
                v.cursor = result.newChild("Cursor")
                let cursorFrames = @[
                    imageWithDoomPicture(v.gameData.pictures["M_SKULL1"], v.gameData.palettes[0]),
                    imageWithDoomPicture(v.gameData.pictures["M_SKULL2"], v.gameData.palettes[0])
                ]
                let cursorAnimImage = newAnimatedImageWithImageSeq(cursorFrames)
                v.cursor.translation = newVector3(itemNode.translation.x - 32, y - itemImage.size.height.Coord - 5, 0)

                let cursorSprite = v.cursor.component(Sprite)
                cursorSprite.image = cursorAnimImage

                let cursorAnimation = cursorAnimImage.frameAnimation(desiredFramerate=4)

                result.sceneView().addAnimation(cursorAnimation)

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

    let bgNode = v.rootNode.newChild("TITLEPIC")
    let bgDoomPic = v.gameData.pictures["TITLEPIC"]
    let bgSprite = bgNode.component(Sprite)
    bgSprite.image = imageWithDoomPicture(bgDoomPic, v.gameData.palettes[0])

    let logoNode = v.rootNode.newChild("M_DOOM")
    let logoDoomPic = v.gameData.pictures["M_DOOM"]
    logoNode.translation = newVector3(VIEWPORT_SIZE.width / 2 - logoDoomPic.width / 2 - 2, 3, 0)
    let logoSprite = logoNode.component(Sprite)
    logoSprite.image = imageWithDoomPicture(logoDoomPic, v.gameData.palettes[0])

    discard v.createDoomMenu(v.rootNode)

    v.setNeedsDisplay()

method draw(v: MenuView, r: Rect) =
    procCall v.SceneView.draw(r)
