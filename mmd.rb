require 'kconv'

class MMDModel
    attr_reader :header
    attr_reader :vertices
    attr_reader :face
    attr_reader :materials
    
    def load(io)
        reader = MMDReader.new(io)
    
        @header = load_header(reader)
        @vertices = load_vertices(reader)
        @face = load_face(reader)
        @materials = load_materials(reader)
    end
    
    def load_header(reader)
        header = MMDHeader.new()
        header.load(reader)
        
        return header
    end
    
    def load_vertices(reader)
        vertices = Array.new()

        reader.int().times{|index|
            vertex = MMDVertex.new()

            vertex.load(reader)
            vertices[index] = vertex
        }
        
        return vertices
    end
    
    def load_face(reader)
        face = MMDFace.new()
        face.load(reader)
        
        return face
    end
    
    def load_materials(reader)
        materials = Array.new()
        
        reader.int().times{|index|
            material = MMDMaterial.new()
            material.load(reader)
            materials[index] = material
        }
        
        return materials
    end
end

class MMDHeader
    attr_reader :magic
    attr_reader :version
    attr_reader :name
    attr_reader :comment
    
    def load(reader)
        @magic = reader.string(3)
        @version = reader.float()
        @name = reader.string(20)
        @comment = reader.string(256)
    end
end

class MMDVertex
    attr_reader :pos
    attr_reader :normal
    attr_reader :uv
    attr_reader :bone_nums
    attr_reader :bone_weight
    attr_reader :edge_flag
    
    def load(reader)
        @pos = reader.floats(3)
        @normal = reader.floats(3)
        @uv = reader.floats(2)
        @bone_nums = reader.ushorts(2)
        @bone_weight = reader.byte()
        @edge_flag = reader.byte() == 1
    end
end

class MMDFace
    attr_reader :indices

    def load(reader)
        count = reader.int()
        @indices = reader.ushorts(count)
    end
end

class MMDMaterial
    attr_reader :diffuse
    attr_reader :alpha
    attr_reader :specularity
    attr_reader :specular
    attr_reader :ambient
    attr_reader :toon_index
    attr_reader :edge_flag
    attr_reader :vert_count
    attr_reader :texture
    attr_reader :sphere
    
    def load(reader)
        @diffuse = reader.floats(3)
        @alpha = reader.float()
        @specularity = reader.float()
        @specular = reader.floats(3)
        @ambient = reader.floats(3)
        @toon_index = reader.byte()
        @edge_flag = reader.byte() == 1
        @vert_count = reader.int()
        
        filename = reader.string(20).split('*')
        @texture = filename[0]
        
        if filename.length == 2
            @sphere = filename[1]
        end
    end
end

class MMDReader
    def initialize(io)
        @io = io
    end

    def byte()
        return @io.read(1).unpack('C')[0]
    end

    def ushort()
        return @io.read(2).unpack('S')[0]
    end

    def ushorts(count)
        return @io.read(2 * count).unpack("S#{count}")
    end

    def int()
        return @io.read(4).unpack('i')[0]
    end

    def float()
        return @io.read(4).unpack('f')[0]
    end
    
    def floats(count)
        return @io.read(4 * count).unpack("f#{count}")
    end
    
    def string(count)
        return @io.read(count).unpack('Z*')[0].toutf8()
    end
end
