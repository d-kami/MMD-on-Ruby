require './mmdr.rb'

class MMDMotion
    attr_reader :header
    attr_reader :motions
    attr_reader :skins

    def load(io)
        reader = MMDReader.new(io)
        
        @header = load_header(reader)
        @motions = load_motions(reader)
        @skins = load_skins(reader)
    end
    
    def load_header(reader)
        header = MMDMotionHeader.new()
        header.load(reader)
        
        return header
    end
    
    def load_motions(reader)
        motions = Array.new()
    
        reader.int().times{|index|
            motion = MMDMotionData.new()
            motion.load(reader)
            motions[index] = motion
        }
        
        return motions
    end
    
    def load_skins(reader)
        skins = Array.new()
        
        reader.int().times{|index|
            skin = MMDSkinMotion.new()
            skin.load(reader)
            
            skins[index] = skin
        }
        
        return skins
    end
end

class MMDMotionHeader
    attr_reader :header
    attr_reader :name
    
    def load(reader)
        @header = reader.string(30)
        @name = reader.string(20)
    end
end

class MMDMotionData
    attr_reader :bone_name
    attr_reader :flame_no
    attr_reader :location
    attr_reader :rotation
    attr_reader :interpolation
    
    def load(reader)
        @bone_name = reader.string(15)
        @flame_no = reader.int()
        @location = reader.floats(3)
        @rotation = reader.floats(4)
        @interpolation = reader.bytes(64)
    end
end

class MMDSkinMotion
    attr_reader :name
    attr_reader :flame_no
    attr_reader :weight
    
    def load(reader)
        @name = reader.string(15)
        @flame_no = reader.int()
        @weight = reader.float()
    end
end
