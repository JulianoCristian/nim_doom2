import nimx.context
import nimx.image
import nimx.types
import nimx.view

import rod.rod_types
import rod.node

type MenuView* = ref object of View
    img*: Image
    imgpos*: Rect

proc newMenuView*(r: Rect): MenuView =
    result.new
    result.init(r)

method init(v: MenuView, r: Rect) =
    discard

method draw*(v: MenuView, r: Rect) =
    procCall v.View.draw(r)
    let c = currentContext()
    c.drawImage(v.img, v.imgpos)
