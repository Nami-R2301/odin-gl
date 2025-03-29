package odin_gl

import "core:fmt"
import gl "vendor:OpenGL"
import "vendor:glfw"
import libc "core:c/libc"

hello_triangle_program: u32 = 0;

main :: proc() {
    fmt.println("[INFO]:\t\tStarting", "app...", sep = " ");

    minor, major, rev : i32;

    major, minor, rev = glfw.GetVersion();
    fmt.printfln("[INFO]:\t\tGLFW version (%d,%d,%d)", major, minor, rev);

    glfw.SetErrorCallback(error_handler_GLFW);
    assert(cast (bool) glfw.Init(), "Cannot init GLFW");
    fmt.println("[INFO]:\t\tGLFW initialized");

    glfw.WindowHint_int(glfw.REFRESH_RATE, glfw.DONT_CARE);
    window := glfw.CreateWindow(640, 480, title = "Hello World", monitor = nil, share = nil);
    glfw.MakeContextCurrent(window);
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

        glfw.SwapBuffers(window);
    }
}

error_handler_GLFW :: proc "c" (error_code: i32, description: cstring) {
    libc.printf("[ERROR]:\tGLFW error: %s [%d]\n", description, error_code);
    libc.printf("[INFO]:\t\tDestroying GLFW instance...\n");
    window := glfw.GetCurrentContext();
    glfw.DestroyWindow(window);
    glfw.Terminate();
    libc.exit(libc.EXIT_FAILURE);
}

error_handler_GL :: proc "c" (error_code: u32, type: u32, id: u32, severity: u32, length: i32,
    error_message: cstring, user_param: rawptr) {
    severity_str : cstring = "Fatal (Unknown)";
    switch (severity) {
        case gl.DEBUG_SEVERITY_HIGH: severity_str = "Fatal (High)";
        case gl.DEBUG_SEVERITY_MEDIUM: severity_str = "Fatal (Medium)";
        case gl.DEBUG_SEVERITY_LOW: severity_str = "Warn (low)";
        case gl.DEBUG_SEVERITY_NOTIFICATION: severity_str = "Warn (info)";
        case: severity_str = "Fatal (Unknown)";
    }

    libc.printf("[ERROR]:\t[%s] OpenGL error: %s [%d]\n", severity_str, error_message, error_code);
}

init_GL :: proc (window: ^glfw.WindowHandle) -> bool {
    glfw.WindowHint_int(glfw.CONTEXT_VERSION_MAJOR, 4);
    glfw.WindowHint_int(glfw.CONTEXT_VERSION_MINOR, 6);
    glfw.WindowHint_int(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE);
    glfw.WindowHint_bool(glfw.OPENGL_DEBUG_CONTEXT, true);

    gl.load_up_to(4, 6, glfw.gl_set_proc_address);
    fmt.println("[INFO]:\t\tLoaded OpenGL function functions up to 4.6");

    gl.Enable(gl.DEBUG_OUTPUT);  // Enable debug output.
    gl.Enable(gl.DEBUG_OUTPUT_SYNCHRONOUS);  // Call the callback as soon as there's an error.
    gl.DebugMessageCallback(error_handler_GL, nil);
    // Filter the messages we want to debug or not with the last param 'enabled'.
    gl.DebugMessageControl(gl.DONT_CARE, gl.DEBUG_TYPE_OTHER, gl.DONT_CARE, 0, nil, gl.FALSE);

    gl.Enable(gl.DEPTH_TEST);
    gl.Enable(gl.BLEND);

    gl.ClearColor(0.18, 0.18, 0.18, 1.0);
    gl.Viewport(0, 0, glfw.GetWindowSize(window^));

    program_id, is_ok := gl.load_shaders_file("shaders/hello_triangle.vert", "shaders/hello_triangle.frag");
    hello_triangle_program = program_id;

    return is_ok;
}

init_vulkan :: proc() -> bool {
    glfw.WindowHint_int(glfw.CLIENT_API, glfw.NO_API);

    if !glfw.VulkanSupported() {
        // VulkanSDK not supported...
        fmt.println("[ERROR]:\tCannot init Vulkan: Vulkan not supported");
        return false;
    }

    if !cast(bool) glfw.ExtensionSupported("GL_ARB_gl_spirv") {
        // Cannot compile SPIR_V for Vulkan...
        fmt.println("[ERROR]:\tCannot init Vulkan: SPIRV extension not supported");
        return false;
    }
    return true;
}