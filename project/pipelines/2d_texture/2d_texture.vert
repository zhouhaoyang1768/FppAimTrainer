#version 410 core

layout(location=0) in vec2 aPosition;
layout(location=1) in vec2 aTextureCoords;

out vec2 vTexCoords;

uniform mat4 projection;

void main()
{
	vTexCoords = aTextureCoords;
	gl_Position = vec4(aPosition, 0, 1.0);
}


