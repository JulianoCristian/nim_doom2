import strutils
import tables

import nimx.button
import nimx.context
import nimx.event
import nimx.font
import nimx.image
import nimx.keyboard
import nimx.types
import nimx.view
import nimx.window

import rod.animated_image
import rod.edit_view
import rod.node
import rod.rod_types
import rod.viewport

import rod.component
import rod.component.camera
import rod.component.sprite

import wad.doomdata

import picture


const
    VIEWPORT_SIZE = newSize(320, 200)


type MenuItem = ref object
    pic:     string         ## Name of picture (LUMP name in *.wad file)
    subMenu: seq[MenuItem]  ## Current menu item subMenu (empty seq if no submenu)
    action:  proc()         ## Action to perform (items without subMenus,
                            ## like 'Quit Game')

proc newMenuItem(pic: string, subMenu: seq[MenuItem] = @[], action: proc() = nil): MenuItem =
    result.new
    result.pic = pic
    result.subMenu = subMenu
    result.action = action


type MenuView* = ref object of SceneView
    gameData:       DoomData        ## Typed data loaded from *.wad file
    mainMenu:       seq[MenuItem]   ## General Main menu hierarchical structure
    mainMenuRoot:   MenuItem        ## Current parent for displayed menu (nil for root)
    mainMenuCursor: int             ## Current position of 'skull' cursor


proc newNodeWithDoomPic(v: MenuView, name: string, parent: Node, pic: string, x: Coord = 0, y: Coord = 0, center: bool = false): Node =
    ## Create new Rod Engine scene view node with name, attach it to parent,
    ## and create ROD Sprite node component with picture fetched from *.wad
    ## file by `pic` - lump name.

    # Add new node
    result = parent.newChild(name)

    # Create static image for sprite from *.wad picture
    let nodeImage = imageWithDoomPicture(v.gameData.pictures[pic], v.gameData.palettes[0])

    # Create sprite component for node
    let nodeSprite = result.component(Sprite)
    nodeSprite.image = nodeImage

    # Setup node position
    result.translation = newVector3(x + (if center: VIEWPORT_SIZE.width / 2 - nodeImage.size.width / 2 else: 0).Coord, y, 0)


proc newAnimatedNodeWithDoomPic(v: MenuView, name: string, parent: Node, pics: seq[string], frameRate: int, x: Coord = 0, y: Coord = 0, center: bool = false): Node =
    ## The same as `newNodeWithDoomPic` but takes sequence of picture in order
    ## to create animated sprite.

    # Add new node
    result = parent.newChild(name)

    # Create animated image for sprite from *.wad pictures
    var frames: seq[Image] = @[]
    for pic in pics: frames.add(imageWithDoomPicture(v.gameData.pictures[pic], v.gameData.palettes[0]))
    let nodeImage = newAnimatedImageWithImageSeq(frames)

    # Create sprite component for node
    let nodeSprite = result.component(Sprite)
    nodeSprite.image = nodeImage

    # Setup node position, add animation to NimX Window in order to play it
    result.translation = newVector3(x + (if center: VIEWPORT_SIZE.width / 2 - nodeImage.size.width / 2 else: 0).Coord, y, 0)
    result.sceneView().addAnimation(nodeImage.frameAnimation(frameRate))


proc newMenuView*(r: Rect, gameData: DoomData): MenuView =
    # Main Menu View constructor
    result.new
    result.gameData = gameData

    # Create main menu and its submenus structure
    result.mainMenu = @[
        newMenuItem("M_NGAME",  @[                # New Game sub-menu
            newMenuItem("M_JKILL"),
            newMenuItem("M_ROUGH"),
            newMenuItem("M_HURT"),
            newMenuItem("M_ULTRA"),
            newMenuItem("M_NMARE")
        ]),
        newMenuItem("M_OPTION", @[                # Options sub-menu
            newMenuItem("M_ENDGAM")
        ]),
        newMenuItem("M_LOADG", @[                 # Load Game sub-menu
            newMenuItem("M_ENDGAM")
        ]),
        newMenuItem("M_SAVEG", @[                 # Save Game sub-menu
            newMenuItem("M_ENDGAM")
        ]),
        newMenuItem("M_QUITG", action = proc() =  # Quit Game menu item
            echo gameData.exitText.toString()
            quit(0)
        )
    ]

proc createDoomMenu*(v: MenuView, n: Node, shiftLeft: Coord = 63): Node =
    result = n.findNode("Menu")
    var y: Coord = 72

    if v.mainMenuRoot.isNil:
        discard v.newNodeWithDoomPic("Logo", v.SceneView.rootNode, "M_DOOM", -2, 3, center=true)

    if v.mainMenuRoot == v.mainMenu[0]:
        discard v.newNodeWithDoomPic("New Game Label", v.SceneView.rootNode, "M_NGAME", 0, 10, center=true)
        discard v.newNodeWithDoomPic("Choose Skill Level", v.SceneView.rootNode, "M_SKILL", 10, 40, center=true)

    for index, item in if v.mainMenuRoot.isNil: v.mainMenu else: v.mainMenuRoot.subMenu:
        let itemNode = v.newNodeWithDoomPic(item.pic, result, item.pic, VIEWPORT_SIZE.width / 2 - shiftLeft, y.Coord, false)
        y += itemNode.component(Sprite).image.size.height.Coord + 1
        if index == v.mainMenuCursor:
            discard v.newAnimatedNodeWithDoomPic(
                "Cursor",
                v.SceneView.rootNode,
                @["M_SKULL1", "M_SKULL2"], 4,
                itemNode.translation.x - 32, y - itemNode.component(Sprite).image.size.height.Coord - 5
            )

proc clearDoomMenu(v: MenuView) =
    v.mainMenuCursor = 0
    v.SceneView.rootNode.findNode("Menu").removeAllChildren()

    var nodesToRemove: seq[Node] = @[
        v.SceneView.rootNode.findNode("Cursor"),
        v.SceneView.rootNode.findNode("Logo"),
        v.SceneView.rootNode.findNode("New Game Label"),
        v.SceneView.rootNode.findNode("Choose Skill Level")
    ]
    for node in nodesToRemove:
        if node.isNil: continue else: node.removeFromParent()

method onKeyDown*(v: MenuView, e: var Event): bool =
    let menuLen = (if not v.mainMenuRoot.isNil: v.mainMenuRoot.subMenu.len else: v.mainMenu.len)
    if e.keyCode == VirtualKey.Down:
        v.mainMenuCursor = (v.mainMenuCursor + 1) mod menuLen
        v.SceneView.rootNode.findNode("Cursor").translation.y = v.SceneView.rootNode.findNode("Menu").children[v.mainMenuCursor].translation.y - 5
        return true
    elif e.keyCode == VirtualKey.Up:
        v.mainMenuCursor = (menuLen + v.mainMenuCursor - 1) mod menuLen
        v.SceneView.rootNode.findNode("Cursor").translation.y = v.SceneView.rootNode.findNode("Menu").children[v.mainMenuCursor].translation.y - 5
        return true
    elif e.keyCode == VirtualKey.Return:
        if not v.mainMenuRoot.isNil:
            if v.mainMenuRoot.subMenu[v.mainMenuCursor].action != nil:
                v.mainMenuRoot.subMenu[v.mainMenuCursor].action()
                return true
        elif v.mainMenuRoot.isNil:
            if v.mainMenu[v.mainMenuCursor].action != nil:
                v.mainMenu[v.mainMenuCursor].action()
                return true
        if v.mainMenuRoot.isNil: v.mainMenuRoot = v.mainMenu[v.mainMenuCursor]
        v.clearDoomMenu()
        discard v.createDoomMenu(v.rootNode, shiftLeft = 112)
        return true
    elif e.keyCode == VirtualKey.Backspace:
        if not v.mainMenuRoot.isNil:
            v.mainMenuRoot = nil
            v.clearDoomMenu()
            discard v.createDoomMenu(v.rootNode)
        return true


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

    discard v.newNodeWithDoomPic("Background", v.rootNode, "TITLEPIC", 0, 0)
    discard v.rootNode.newChild("Menu")
    discard v.createDoomMenu(v.rootNode)

    discard v.makeFirstResponder()

    v.setNeedsDisplay()

method draw(v: MenuView, r: Rect) =
    procCall v.SceneView.draw(r)
