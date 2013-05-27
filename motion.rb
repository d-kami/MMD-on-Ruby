require './mmdr.rb'

class MMDMotion
    attr_reader :header

    def load(io)
        reader = MMDReader.new(io)
        
        @header = load_header(reader)
    end
    
    def load_header(reader)
        header = MMDMotionHeader.new()
        header.load(reader)
        
        return header
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
