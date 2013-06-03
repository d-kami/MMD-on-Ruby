# coding: utf-8

class Vector3
    attr_reader :values

    @@X = 0
    @@Y = 0
    @@Z = 0
    
    def initialize(x = 0, y = 0, z = 0)
        @values = Array.new()
        
        set(x, y, z)
    end

    #index番目の要素を返す
    def [](index)
        return @values[index]
    end
    
    #index番目の要素にvalueを入れる
    def []=(index, value)
        @values[index] = value
    end

    def set(x, y, z)
        @values[@@X] = x
        @values[@@Y] = y
        @values[@@Z] = z
    end
end
