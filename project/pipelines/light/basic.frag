#version 410 core

uniform struct Light
{
	float mColor[3];
	float mPosition[3];
	float mAmbientIntensity;
	float mSpecularIntensity;
	float mSpecularExponent;
} uLight;


in  vec3 vWorldPos;
in  vec3 vNormals;
in  vec3 vCamera;

out vec4 fragColor;

uniform sampler2D sampler1;
uniform vec3 vColor;

void main()
{
//	uLight.mColor[0] = 1.0;
//	uLight.mColor[1] = 1.0;
//	uLight.mColor[2] = 1.0;
//	uLight.mPosition[0] = 0.0;
//	uLight.mPosition[1] = 0.0;
//	uLight.mPosition[2] = 1.0;
//	uLight.mAmbientIntensity = 0.1;
//	uLight.mSpecularIntensity = 2;
//	uLight.mSpecularExponent = 2;
	
	vec3 normal = vNormals / length(vNormals);	

	vec3 lightLoc = vec3(uLight.mPosition[0], uLight.mPosition[1], uLight.mPosition[2]);
	vec3 lightColor = vec3(uLight.mColor[0], uLight.mColor[1], uLight.mColor[2]);
	vec3 lightRay = lightLoc - vWorldPos;
	vec3 color = vColor;//normal.rgb;


	vec3 ambient = color * uLight.mAmbientIntensity;
	vec3 diffuse = vec3(0, 0, 0);
	vec3 specular = vec3(0, 0, 0);
	
	float dotProd = dot(lightRay, normal);
	
	if (dotProd > 0) {
		dotProd = dotProd / length(lightRay);
		dotProd = dotProd / length(normal);
		
		// dotProd = pow(dotProd, 2);

		diffuse.r = dotProd * lightColor.r * color.r;
		diffuse.g = dotProd * lightColor.g * color.g;
		diffuse.b = dotProd * lightColor.b * color.b;


///////////////////////////////////////////
		vec3 r = -lightRay - 2 * normal * (dot(normal, -lightRay));
		vec3 sightRay = vCamera - vWorldPos;
		dotProd = dot(r, sightRay);
		if (dotProd > 0) {
			dotProd = dotProd / length(r);
			dotProd = dotProd / length(sightRay);
			dotProd = pow(dotProd, uLight.mSpecularExponent) * uLight.mSpecularIntensity;
			specular.r = dotProd * lightColor.r * color.r;
			specular.g = dotProd * lightColor.g * color.g;
			specular.b = dotProd * lightColor.b * color.b;
		}
	}

	

	//float dist = length(vWorldPos - vec3(uLight.mPosition[0], uLight.mPosition[1], uLight.mPosition[2]));
	//float intensity = 1.0 - dist * 0.05;
	//if (intensity < 0) intensity = 0;

	fragColor = vec4(ambient + 1 * (diffuse + specular), 1.0);
}

