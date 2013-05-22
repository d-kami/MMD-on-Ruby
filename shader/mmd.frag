uniform float alpha;
uniform float useTexture;
uniform sampler2D sampler;

uniform vec3 ambient;
uniform vec3 lightDir;
uniform vec3 lightDiffuse;

varying vec3 normal;

void main (void)
{
    float cos = dot(normalize(normal), normalize(lightDir));
    vec3 diffuse = lightDiffuse * max(0.0, cos);
    vec3 texture = texture2DProj(sampler, gl_TexCoord[0]).rgb;
    vec3 color = (1.0 - useTexture) * diffuse * gl_Color.rgb + useTexture * texture * diffuse;
    
    gl_FragColor = vec4(ambient + color, alpha);
}
