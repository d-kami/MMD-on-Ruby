uniform float alpha;
uniform vec3 ambient;
uniform sampler2D sampler;
uniform float useTexture;

varying vec3 normal;

vec3 lightDiffuse = vec3(1.0, 1.0, 1.0);
vec3 lightDir = vec3(0.0, 0.0, 1.0);

void main (void)
{
    float cos = dot(normalize(normal), normalize(lightDir));
    vec3 diffuse = lightDiffuse * max(0.0, cos);
    vec3 texture = texture2DProj(sampler, gl_TexCoord[0]).rgb;
    vec3 color = (1.0 - useTexture) * diffuse * gl_Color.rgb + useTexture * texture;
    
    gl_FragColor = vec4(ambient + color, alpha);
}
