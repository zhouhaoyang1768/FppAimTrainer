#version 410 core

in  vec2 vTexCoords;
out vec4 fragColor;

uniform sampler2D text;
uniform vec3 textColor;

void main()
{
	vec4 sampled = vec4(1, 1, 1, texture(text,vTexCoords).r);

	fragColor = vec4(textColor, 1.0) * sampled;
	//fragColor = vec4(1, 0, 0, 1);
}
