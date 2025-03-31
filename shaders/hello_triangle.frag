#version 330 core

layout (location = 0) out vec4 fout_frag_color;

void main() {
    fout_frag_color = vec4(normalize(gl_FragCoord.xyz), 1.0);
}