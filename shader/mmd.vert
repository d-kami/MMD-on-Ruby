uniform bool isEdge;

varying vec3 position;
varying vec3 normal;

void main(void)
{
    vec4 pos = gl_ModelViewProjectionMatrix * gl_Vertex;
    position = (gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1.0)).xyz;
    normal = gl_NormalMatrix * gl_Normal;

    if (isEdge) {
        vec4 pos2 = gl_ModelViewProjectionMatrix * vec4(gl_Vertex.xyz + gl_Normal, 1.0);
        vec4 norm = normalize(pos2 - pos);
        gl_Position = pos + norm * 0.002 * pos.w;
        return;
    }

    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    gl_FrontColor = gl_Color;
    gl_Position = pos;
}
