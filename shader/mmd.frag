uniform bool isEdge;
uniform float alpha;
uniform float shininess;
uniform float useTexture;
uniform sampler2D sampler;
uniform sampler2D toonSampler;
uniform sampler2D sphereSampler;

uniform bool isSphereUse;
uniform bool isSphereAdd;

uniform vec3 ambient;
uniform vec3 specularColor;
uniform vec3 lightDir;
uniform vec3 lightDiffuse;

varying vec3 position;
varying vec3 normal;

vec4 edgeColor = vec4(0.0, 0.0, 0.0, 1.0);

void main (void)
{

    if(isEdge){
        gl_FragColor = edgeColor;
    }else{
        vec3 cameraDir = normalize(-position);
        vec3 halfAngle = normalize(lightDir + cameraDir);
        float specularWeight = pow(max(0.001, dot(halfAngle, normalize(normal))) , shininess);
        vec3 specular = specularWeight * specularColor;
        
        vec3 texture = texture2DProj(sampler, gl_TexCoord[0]).rgb;
        vec3 color = (1.0 - useTexture) * (ambient + gl_Color.rgb + specular) + useTexture * texture;
        
        if(isSphereUse){
            vec2 sphereCoord = 0.5 * (1.0 + vec2(1.0, -1.0) * normalize(normal).xy);
        
            if(isSphereAdd){
                color += texture2D(sphereSampler, sphereCoord).rgb;
            }else{
                color *= texture2D(sphereSampler, sphereCoord).rgb;
            }
        }
        
        color = clamp(color, 0.0, 1.0);

        float dotNL = max(0.0, dot(normalize(lightDir), normalize(normal)));
        vec2 toonCoord = vec2(0.0, 0.5 * (1.0 - dotNL));
        vec3 toon = texture2D(toonSampler, toonCoord).rgb;
        gl_FragColor = vec4(color * toon, alpha);
    }
}
