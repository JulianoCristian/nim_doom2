import nimx.image

import wad.doomdata

proc imageWithDoomPicture*(p: Picture, pal: Palette): Image =
    ## Construct new image with Doom picture
    var bitmap = cast[cstring](alloc0(p.width.int * p.height.int * 4 * sizeof(uint8)))
    for colindex, col in p.columns:
        for post in col.posts:
            for index in 0 ..< post.colors.len:
                let off = ((post.row.int + index) * p.width.int + colindex.int) * 4
                bitmap[off]  = cast[char](pal[post.colors[index]].red)
                bitmap[off + 1] = cast[char](pal[post.colors[index]].green)
                bitmap[off + 2] = cast[char](pal[post.colors[index]].blue)
                bitmap[off + 3] = cast[char](255)

    return imageWithBitmap(cast[ptr uint8](bitmap), p.width.int, p.height.int, 4)
