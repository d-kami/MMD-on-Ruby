uniform bool isEdge;
uniform bool useTexture;
uniform bool isSphereAdd;
uniform bool isSphereUse;

uniform float alpha;
uniform float shininess;

uniform sampler2D sampler;
uniform sampler2D toonSampler;
uniform sampler2D sphereSampler;

uniform vec3 ambient;
uniform vec3 diffuse;
uniform vec3 specularColor;
uniform vec3 lightDir;
uniform vec3 lightDiffuse;

varying vec3 vPosition;
varying vec3 vNormal;
varying vec2 vTexCoord;

vec4 edgeColor = vec4(0.0, 0.0, 0.0, 1.0);

void main (void)
{

    if(isEdge){
        gl_FragColor = edgeColor;
    }else{
        vec3 cameraDir = normalize(-vPosition);
        vec3 halfAngle = normalize(lightDir + cameraDir);
        float specularWeight = pow(max(0.001, dot(halfAngle, normalize(vNormal))) , shininess);
        vec3 specular = specularWeight * specularColor;
        
        vec3 color = (ambient + diffuse + specular);
        
        if(useTexture){
            color *= texture2D(sampler, vTexCoord).rgb;
        }
        
        if(isSphereUse){
            vec2 sphereCoord = 0.5 * (1.0 + vec2(1.0, -1.0) * normalize(vNormal).xy);

            if(isSphereAdd){
                color += texture2D(sphereSampler, sphereCoord).rgb;
            }else{
                color *= texture2D(sphereSampler, sphereCoord).rgb;
            }
        }
        
        color = clamp(color, 0.0, 1.0);

        float dotNL = max(0.0, dot(normalize(lightDir), normalize(vNormal)));
        vec2 toonCoord = vec2(0.0, 0.5 * (1.0 - dotNL));
        vec3 toon = texture2D(toonSampler, toonCoord).rgb;
        gl_FragColor = vec4(color * toon, alpha);
    }
}
