module InitBuffers
    def init_buffers(model)
        buffers = Hash.new()
        
        init_weight(model, buffers)
        init_vectors(model, buffers)
        init_rotations(model, buffers)
        init_positions(model, buffers)
        init_vertex_info(model, buffers)
        init_indices(model, buffers)
        
        return buffers
    end
    
    def init_weight(model, buffers)
        weight = Array.new()

        model.vertices.each_with_index do |vertex, i|
            weight[i] = vertex.bone_weight
        end
        
        buffers[:bone_weight] = create_buffer(weight)
    end
    
    def init_vectors(model, buffers)
        vectors1 = Array.new()
        vectors2 = Array.new()
        
        model.vertices.each_with_index do |vertex, i|
            bone1 = model.bones[vertex.bone_nums[0]]
            bone2 = model.bones[vertex.bone_nums[1]]
            
            3.times do |j|
                vectors1[3 * i + j] = vertex.pos[j] - bone1.pos[j]
                vectors2[3 * i + j] = vertex.pos[j] - bone2.pos[j]
            end
        end
        
        buffers[:vector_from_bone1] = create_buffer(vectors1)
        buffers[:vector_from_bone2] = create_buffer(vectors2)
    end
    
    def init_rotations(model, buffers)
        rotations1 = Array.new()
        rotations2 = Array.new()

        model.vertices.each_with_index do |vertex, i|
            3.times do |j|
                rotations1[4 * i + j] = 0.0
                rotations2[4 * i + j] = 0.0
            end
            
            rotations1[4 * i + 3] = 1.0
            rotations2[4 * i + 3] = 1.0
        end
        
        buffers[:bone1_rotation] = create_buffer(rotations1)
        buffers[:bone2_rotation] = create_buffer(rotations2)
    end
    
    def init_positions(model, buffers)
        positions1 = Array.new()
        positions2 = Array.new()
        
        model.vertices.each_with_index do |vertex, i|
            bone1 = model.bones[vertex.bone_nums[0]]
            bone2 = model.bones[vertex.bone_nums[1]]
            
            3.times do |j|
                positions1[3 * i + j] = bone1.pos[j]
                positions2[3 * i + j] = bone2.pos[j]
            end
        end
        
        buffers[:bone1_position] = create_buffer(positions1)
        buffers[:bone2_position] = create_buffer(positions2)
    end
    
    def init_indices(model, buffers)
        indexBuffer = GL.GenBuffers(1)[0]
        GL.BindBuffer(GL::ELEMENT_ARRAY_BUFFER, indexBuffer)
        GL.BufferData(GL::ELEMENT_ARRAY_BUFFER, model.face.indices.length * 2, model.face.indices.pack('v*'), GL_STATIC_DRAW);
        buffers[:indices] = indexBuffer
    end
    
    def init_vertex_info(model, buffers)
        normals = Array.new()
        texcoords = Array.new()

        model.vertices.length.times{|index|
            normals[index] = model.vertices[index].normal
            texcoords[index] = model.vertices[index].uv
        }
        
        buffers[:normal] = create_buffer(normals.flatten())
        buffers[:texcoord] = create_buffer(texcoords.flatten())
    end
    
    def create_buffer(array)
        buffer = GL.GenBuffers(1)[0]
        GL.BindBuffer(GL::ARRAY_BUFFER, buffer)
        GL.BufferData(GL::ARRAY_BUFFER, 4 * array.size, array.pack('f*'), GL_STATIC_DRAW)

        return buffer
    end
end
