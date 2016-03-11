import nimx.naketools

beforeBuild = proc(b: Builder) =
    b.appName = "doom2"
    b.mainFile = "src"/"main.nim"
