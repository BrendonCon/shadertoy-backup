# Shadertoy Backup
This repository serves as a backup for some of my [shadertoy](http://www.shadertoy.com) projects and experiments. It serves as a history for personal progress and a point of reference. 

The shaders have been ported to a GLSLCanvas friendly syntax, this includes some subtle changes such as renaming of uniforms. Be aware of this when trying to run these shaders in other environments that they may not work as intended.

## Usage
This is currently only suited to usage with GLSL canvas which can be setup as followed:

- Open VSCode and install [glsl-canvas](https://marketplace.visualstudio.com/items?itemName=circledev.glsl-canvas)
- Create a `glsl` file
- Press **F1** and type: **Show glslCanvas**

## Folder Structure
- **src**: Source folder where our code lies
  - **common**: Common functions housed here
  - **shaders**: Fragment shaders live here
  - **templates**: As you guessed, fragment shader base templates live here

## MIT License
Copyright (c) 2020 Brendon Conradie

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
