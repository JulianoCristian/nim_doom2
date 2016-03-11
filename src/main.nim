import tables
import streams

import nimx.app
import nimx.context
import nimx.image
import nimx.resource
import nimx.system_logger
import nimx.view
import nimx.window

import wad.doomdata

import picture
import view_menu

const isMobile = defined(ios) or defined(android)

var gameData: DoomData

proc startApplication() =
    var mainWindow : Window

    when isMobile:
        mainWindow = newFullscreenWindow()
    else:
        mainWindow = newWindow(newRect(120, 120, 320, 200))

    mainWindow.title = "Doom2: Hell on Earth"

    var menuView : MenuView = newMenuView(newRect(0, 0, 320, 200))
    menuView.autoresizingMask = { afFlexibleMaxX, afFlexibleMaxY }
    mainWindow.addSubview(menuView)

    loadResourceAsync "Doom2.wad" proc(s: Stream) =
        gameData = newDoomData(s)

        let doomPic = gameData.pictures["TITLEPIC"]
        menuView.img = imageWithDoomPicture(doomPic, gameData.palettes[0])
        menuView.imgpos = newRect(doomPic.leftOffset.Coord, doomPic.topOffset.Coord, doomPic.width.Coord, doomPic.height.Coord)

when defined js:
    import dom
    dom.window.onload = proc (e: dom.Event) =
        startApplication()
else:
    try:
        startApplication()
        runUntilQuit()
    except:
        logi "Exception caught: ", getCurrentExceptionMsg()
        logi getCurrentException().getStackTrace()
        quit 1
