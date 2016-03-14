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

proc startApplication() =
    var mainWindow : Window

    when isMobile:
        mainWindow = newFullscreenWindow()
    else:
        mainWindow = newWindow(newRect(120, 120, 320, 200))

    mainWindow.title = "Doom2: Hell on Earth"

    loadResourceAsync "Doom2.wad" proc(s: Stream) =
        let gameData = newDoomData(s)
        let menuView = newMenuView(newRect(0, 0, 320, 200), gameData)
        menuView.autoresizingMask = { afFlexibleMaxX, afFlexibleMaxY, afFlexibleWidth, afFlexibleHeight }
        mainWindow.addSubview(menuView)

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
