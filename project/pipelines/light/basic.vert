#version 410 core

layout(location=0) in vec3 aPosition;
layout(location=1) in vec3 aNormal;
//layout(location=2) in vec2 aTexture;

out vec3 vWorldPos;
out vec3 vNormals;
out vec3 vCamera;

uniform mat4 uModel;
uniform mat4 uView;
uniform mat4 uProjection;


void main()
{

	vNormals = (uModel * vec4(aNormal, 0.0f)).xyz;
	vWorldPos = (uModel * vec4(aPosition, 1.0f)).xyz;
	vCamera.x = -uView[3][0];
	vCamera.y = -uView[3][1];
	vCamera.z = -uView[3][2];
	
//    vs_out.texCoord = aTexture;

	vec4 finalPosition = uProjection * uView * uModel * vec4(aPosition,1.0f);

	// Note: Something subtle, but we need to use the finalPosition.w to do the perspective divide
	gl_Position = vec4(finalPosition.x, finalPosition.y, finalPosition.z, finalPosition.w);
}


