module Shader
    #シェーダの読み込み、コンパイル、Uniform変数へのリンク
    def load_shader(vert_shader, frag_shader)
        program = create_program("./shader/#{vert_shader}", "./shader/#{frag_shader}")
        
        locations = init_locations(program)
        init_attributes(program, locations);
        
        return program, locations
    end
    
    def init_locations(program)
        locations = Hash.new()
    
        locations[:is_edge] = GL.GetUniformLocation(program, 'isEdge')
        locations[:alpha] = GL.GetUniformLocation(program, 'alpha')
        locations[:ambient] = GL.GetUniformLocation(program, 'ambient')
        locations[:sampler] = GL.GetUniformLocation(program, 'sampler')
        locations[:toon_sampler] = GL.GetUniformLocation(program, 'toonSampler')
        locations[:use_texture] = GL.GetUniformLocation(program, 'useTexture')
        locations[:light_diffuse] = GL.GetUniformLocation(program, 'lightDiffuse')
        locations[:light_dir] = GL.GetUniformLocation(program, 'lightDir')
        locations[:shininess] = GL.GetUniformLocation(program, 'shininess')
        locations[:specular_color] = GL.GetUniformLocation(program, 'supecularColor')
        locations[:diffuse] = GL.GetUniformLocation(program, 'diffuse')
        locations[:is_sphere_use] = GL.GetUniformLocation(program, 'isSphereUse')
        locations[:is_sphere_add] = GL.GetUniformLocation(program, 'isSphereAdd')
        locations[:sphere_sampler] = GL.GetUniformLocation(program, 'sphereSampler')
        
        return locations
    end
    
    def init_attributes(program, locations)
        attribute(program, locations, :bone_weight, 'boneWeight')
        attribute(program, locations, :vector_from_bone1, 'vectorFromBone1')
        attribute(program, locations, :vector_from_bone2, 'vectorFromBone2')
        attribute(program, locations, :bone1_rotation, 'bone1Rotation')
        attribute(program, locations, :bone2_rotation, 'bone2Rotation')
        attribute(program, locations, :bone1_position, 'bone1Position')
        attribute(program, locations, :bone2_position, 'bone2Position')
        attribute(program, locations, :normal, 'vertNormal')
        attribute(program, locations, :texcoord, 'texCoord')
    end
    
    def attribute(program, locations, label, name)
        locations[label] = GL.GetAttribLocation(program, name)
        GL.EnableVertexAttribArray(locations[label])
    end
    
    #シェーダをコンパイルして、リンクする
    def create_program(vert_name, frag_name)
        program = GL.CreateProgram()
        
        vert_shader = create_shader(vert_name, GL_VERTEX_SHADER)
        frag_shader = create_shader(frag_name, GL_FRAGMENT_SHADER)
        
        GL.AttachShader(program, vert_shader)
        GL.AttachShader(program, frag_shader)
        GL.LinkProgram(program)
        
        if !GL.GetProgramiv(program, GL_LINK_STATUS)
            raise(GL.GetProgramInfoLog(program))
        end

        GL.DeleteShader(vert_shader)
        GL.DeleteShader(frag_shader)

        return program
    end

    #シェーダのコンパイルする
    def create_shader(file_name, type)
        shader = GL.CreateShader(type)
        
        File.open(file_name, 'rb') { |file|
            GL.ShaderSource(shader, file.read())
            GL.CompileShader(shader)
            
            if !GL.GetShaderiv(shader, GL_COMPILE_STATUS)
                raise(GL.GetShaderInfoLog(shader))
            end
        }
        
        return shader
    end
    
    def send_attributes(buffers, locations)
        send_attribute(buffers, locations, :bone_weight, 1)
        send_attribute(buffers, locations, :vector_from_bone1, 3)
        send_attribute(buffers, locations, :vector_from_bone2, 3)
        send_attribute(buffers, locations, :bone1_rotation, 4)
        send_attribute(buffers, locations, :bone2_rotation, 4)
        send_attribute(buffers, locations, :bone1_position, 3)
        send_attribute(buffers, locations, :bone2_position, 3)
        send_attribute(buffers, locations, :normal, 3)
        send_attribute(buffers, locations, :texcoord, 2)
    end
    
    def send_attribute(buffers, locations, label, size)
        GL.BindBuffer(GL_ARRAY_BUFFER, buffers[label])
        GL.VertexAttribPointer(locations[label], size, GL_FLOAT, false, 0, 0)
    end
end
