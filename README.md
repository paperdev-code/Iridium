# Iridium
An application development framework made in Zig.

## How to use
* Probably fork, cause you'll be editing things here and there if you're using this at this stage.
* Write your application in the `app` folder.
* `res` folder contents are copied to `zig-out/bin` when built.
* Use whatever parts u want from the `iridium` package
* Run `zig build` as normal

Alternatively you can `@import` the `build.zig` file and run the `addIridium()` function in your build process.

## Libraries
- [x] GLFW
- [x] GLAD
- [x] Dear ImGui
- [ ] Assets (stb libraries)
- [ ] Audio (OpenAL..?)

## Features
- [x] Window wrapper
- [x] Input wrapper
- [x] Shaders
- [x] Renderer
- [ ] Texture loading

## Requirements
Currently supports `linux`, must have `x11` and `gl` development packages installed.

## Compilation
To view the whole build process, read through the `build.zig` and `libbuild.zig` files in `lib`. Currently only Linux is supported. But care is taken to make it possible to compile on *at least* Windows in the future with minimal system dependencies. I just don't feel like setting that up at the moment.

##### Won't compile?
###### uhh, send log..?