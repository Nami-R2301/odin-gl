#version 330 core

layout (location = 0) in vec3 vin_position;

void main() {
    gl_Position = vec4(vin_position, 1.0);
}