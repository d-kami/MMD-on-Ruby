uniform bool isEdge;

attribute float boneWeight;
attribute vec3 vectorFromBone1;
attribute vec3 vectorFromBone2;
attribute vec4 bone1Rotation;
attribute vec4 bone2Rotation;
attribute vec3 bone1Position;
attribute vec3 bone2Position;
attribute vec3 vertNormal;
attribute vec2 texCoord;

varying vec3 vPosition;
varying vec3 vNormal;
varying vec2 vTexCoord;

vec3 qtransform(vec4 q, vec3 v) {
    return v + 2.0 * cross(cross(v, q.xyz) - q.w*v, q.xyz);
}

void main(void)
{
    vec3 position = qtransform(bone1Rotation, vectorFromBone1) + bone1Position;
    vec3 normal = qtransform(bone1Rotation, vertNormal);

    vPosition = (gl_ModelViewProjectionMatrix * vec4(position, 1.0)).xyz;
    vNormal = gl_NormalMatrix * normal;

    if (boneWeight < 0.99) {
        vec3 p2 = qtransform(bone2Rotation, vectorFromBone2) + bone2Position;
        vec3 n2 = qtransform(bone2Rotation, normal);

        position = mix(p2, position, boneWeight);
        normal = normalize(mix(n2, normal, boneWeight));
    }

    if (isEdge) {
        vec4 pos = gl_ModelViewProjectionMatrix * vec4(position, 1.0);
        vec4 pos2 = gl_ModelViewProjectionMatrix * vec4(position + normal, 1.0);
        vec4 norm = normalize(pos2 - pos);
        gl_Position = pos + norm * 0.05;
        return;
    }

    vTexCoord = texCoord;
    gl_Position = gl_ModelViewProjectionMatrix * vec4(position, 1.0);
}
