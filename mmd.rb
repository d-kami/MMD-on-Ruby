require 'kconv'

class MMDModel
    attr_reader :header
    attr_reader :vertices
    attr_reader :face
    attr_reader :materials
    attr_reader :bones
    attr_reader :iks
    attr_reader :skins
    attr_reader :skin_list
    attr_reader :bone_names
    attr_reader :bone_disps
    attr_reader :ext_header
    
    def load(io)
        reader = MMDReader.new(io)
    
        @header = load_header(reader)
        @vertices = load_vertices(reader)
        @face = load_face(reader)
        @materials = load_materials(reader)
        @bones = load_bones(reader)
        @iks = load_iks(reader)
        @skins = load_skins(reader)
        @skin_list = load_skin_list(reader)
        @bone_names = load_bone_names(reader)
        @bone_disps = load_bone_disps(reader)
        
        if reader.eof?()
            return
        end
        
        @ext_header = load_ext_header(reader)
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
    
    def load_bones(reader)
        bones = Array.new()
        
        reader.ushort().times{|index|
            bone = MMDBone.new()
            bone.load(reader)
            bones[index] = bone
        }
        
        return bones
    end
    
    def load_iks(reader)
        iks = Array.new()
        
        reader.ushort().times{|index|
            ik = MMDIK.new()
            ik.load(reader)
            iks[index] = ik
        }
        
        return iks
    end
    
    def load_skins(reader)
        skins = Array.new()
        
        reader.ushort().times{|index|
            skin = MMDSkin.new()
            skin.load(reader)
            skins[index] = skin
        }
        
        return skins
    end
    
    def load_skin_list(reader)
        skin_list = MMDSkinList.new()
        skin_list.load(reader)
        
        return skin_list
    end
    
    def load_bone_names(reader)
        bone_names = MMDBoneNames.new()
        bone_names.load(reader)
        
        return bone_names
    end
    
    def load_bone_disps(reader)
        bone_disps = Array.new()
        
        reader.int().times{|index|
            bone_disp = MMDBoneDisp.new()
            bone_disp.load(reader)
            bone_disps[index] = bone_disp
        }
        
        return bone_disps
    end
    
    def load_ext_header(reader)
        ext_header = MMDExtHeader.new()
        ext_header.load(reader)
        
        return ext_header
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

class MMDBone
    attr_reader :name
    attr_reader :parent_index
    attr_reader :tail_index
    attr_reader :type
    attr_reader :ik_parent
    attr_reader :pos
    
    def load(reader)
        @name = reader.string(20)
        @parent_index = reader.short()
        @tail_index = reader.short()
        @type = reader.byte()
        @ik_parent = reader.short()
        @pos = reader.floats(3)
    end
end

class MMDIK
    attr_reader :bone_index
    attr_reader :target_index
    attr_reader :length
    attr_reader :iterations
    attr_reader :weight
    attr_reader :children
    
    def load(reader)
        @bone_index = reader.ushort()
        @target_index = reader.ushort()
        @length = reader.byte()
        @iterations = reader.ushort()
        @weight = reader.float()
        @children = reader.ushorts(@length)
    end
end

class MMDSkin
    attr_reader :name
    attr_reader :vert_count
    attr_reader :type
    attr_reader :vertices
    
    def load(reader)
        @name = reader.string(20)
        @vert_count = reader.int()
        @type = reader.byte()
        
        @vertices = Array.new()
        @vert_count.times{|index|
            vertex = MMDSkinVertex.new()
            vertex.load(reader)
            vertices[index] = vertex
        }
    end
end

class MMDSkinVertex
    attr_reader :index
    attr_reader :pos
    
    def load(reader)
        @index = reader.int()
        @pos = reader.floats(3)
    end
end

class MMDSkinList
    attr_reader :indices
    
    def load(reader)
        count = reader.byte()
        @indices = reader.ushorts(count)
    end
end

class MMDBoneNames
    attr_reader :names
    
    def load(reader)
        count = reader.byte()
        @names = Array.new()
        
        count.times{|index|
            names[index] = reader.string(50)
        }
    end
end

class MMDExtHeader
    attr_reader :has_english
    attr_reader :name
    attr_reader :comment
    
    def load(reader)
        @has_english = reader.byte()
        @name = reader.string(20)
        @comment = reader.string(256)
    end
end

class MMDBoneDisp
    attr_reader :bone_index
    attr_reader :disp_index
    
    def load(reader)
        @bone_index = reader.ushort()
        @disp_index = reader.byte()
    end
end

class MMDReader
    def initialize(io)
        @io = io
    end

    def byte()
        return @io.read(1).unpack('C')[0]
    end

    def short()
        return @io.read(2).unpack('s')[0]
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
    
    def eof?()
        return @io.eof?()
    end
end
