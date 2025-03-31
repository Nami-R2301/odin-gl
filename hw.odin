package odin_gl

import "core:fmt"
import gl "vendor:OpenGL"
import "vendor:glfw"
import libc "core:c/libc"

main :: proc() {
    fmt.println("[INFO]:\t\tStarting app...");

    minor, major, rev : i32;
    major, minor, rev = glfw.GetVersion();
    fmt.printfln("[INFO]:\t\tGLFW version (%d,%d,%d)", major, minor, rev);

    glfw.SetErrorCallback(error_handler_GLFW);
    assert(cast (bool) glfw.Init(), "Cannot init GLFW");
    fmt.println("[INFO]:\t\tGLFW initialized");

    glfw.WindowHint_int(glfw.REFRESH_RATE, glfw.DONT_CARE);
    window := glfw.CreateWindow(640, 480, title = "Hello World", monitor = nil, share = nil);
    glfw.MakeContextCurrent(window);
    glfw.SetFramebufferSizeCallback(window, glfw_framebuffer_callback);
    glfw.SwapInterval(1);

    defer {
        fmt.println("[INFO]:\t\tDestroying GLFW window...");
        glfw.DestroyWindow(window);
        glfw.Terminate();
    }

    if !init_GL(&window) {
        fmt.println("[ERROR]:\tCannot init OpenGL: cannot load shaders");
        return
    }

    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents();
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
        gl.DrawArrays(gl.TRIANGLES, 0, 3);  // Draw three sets of vertices.
        glfw.SwapBuffers(window);
    }
}

error_handler_GLFW :: proc "c" (error_code: i32, description: cstring) {
    libc.printf("[ERROR]:\tGLFW error: %s [%d]\n", description, error_code);
    libc.printf("[INFO]:\t\tDestroying GLFW instance...\n");
    libc.fflush(libc.stdout);  // Force a flush, since without it, the messages don't print on time
    window := glfw.GetCurrentContext();
    glfw.DestroyWindow(window);
    glfw.Terminate();
    libc.exit(libc.EXIT_FAILURE);
}

glfw_framebuffer_callback :: proc "c" (window: glfw.WindowHandle, width: i32, height: i32) {
    libc.printf("[INFO]:\t\tFramebuffer resized: (%d,%d)\n", width, height);
    libc.fflush(libc.stdout);
    gl.Viewport(0, 0, width, height);  // Refresh framebuffer viewport
}

init_GL :: proc (window: ^glfw.WindowHandle) -> bool {
    // Use 3.3 core driver since we are doing a very basic pipeline setup.
    glfw.WindowHint_int(glfw.CONTEXT_VERSION_MAJOR, 3);
    glfw.WindowHint_int(glfw.CONTEXT_VERSION_MINOR, 3);
    glfw.WindowHint_int(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE);
    glfw.WindowHint_bool(glfw.OPENGL_DEBUG_CONTEXT, true);

    gl.load_up_to(3, 3, glfw.gl_set_proc_address);
    fmt.println("[INFO]:\t\tBinded OpenGL function addresses up to 3.3");

    gl.Enable(gl.DEPTH_TEST);
    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    gl.ClearColor(0.18, 0.18, 0.18, 1.0);
    gl.Viewport(0, 0, glfw.GetWindowSize(window^));

    program_id, is_ok := gl.load_shaders_file("shaders/hello_triangle.vert", "shaders/hello_triangle.frag");

    if !is_ok {
        return false;
    }

    hello_triangle_program : u32 = program_id;
    fmt.printfln("[INFO]:\t\tGL program ID: %d", hello_triangle_program);
    gl.UseProgram(hello_triangle_program);  // Load shader program here since, we only have one

    vao, vbo : u32;
    // Hardcode vertices for triangle since this is a demo anyway.
    vertices: [9]f32 = {
       -0.5, -0.5,  0.0,
        0.5, -0.5,  0.0,
        0.0,  0.5,  0.0,
    };

    gl.GenVertexArrays(1, &vao);
    gl.GenBuffers(1, &vbo);

    gl.BindVertexArray(vao);
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
    // Should be STATIC_DRAW, but choosing dynamic to silence OpenGL driver warnings.
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.DYNAMIC_DRAW);

    // Setup vao binding for vertex position.
    gl.EnableVertexAttribArray(0);  // layout location = 0
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 0, cast(uintptr) 0);  // vin_position

    return is_ok;
}