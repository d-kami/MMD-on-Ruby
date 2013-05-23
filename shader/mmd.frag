uniform bool isEdge;
uniform float alpha;
uniform float useTexture;
uniform sampler2D sampler;
uniform sampler2D toonSampler;

uniform vec3 ambient;
uniform vec3 lightDir;
uniform vec3 lightDiffuse;

varying vec3 normal;

vec4 edgeColor = vec4(0.0, 0.0, 0.0, 1.0);

void main (void)
{

    if(isEdge){
        gl_FragColor = edgeColor;
    }else{
        vec3 texture = texture2DProj(sampler, gl_TexCoord[0]).rgb;
        vec3 color = ambient + (1.0 - useTexture) * gl_Color.rgb + useTexture * texture;
        color = clamp(color, 0.0, 1.0);

        vec2 toonCoord = vec2(0.0, 0.5 * (1.0 - dot(normalize(lightDir), normalize(normal))));
        vec3 toon = texture2D(toonSampler, toonCoord).rgb;
        gl_FragColor = vec4(color * toon, alpha);
    }
}
