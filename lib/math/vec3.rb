# coding: utf-8

class Vector3
    attr_reader :values

    @@X = 0
    @@Y = 1
    @@Z = 2
    @@COUNT = 3
    
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
    
    #引数のベクトルもしくは配列の値をこのベクトルに格納する
    def set_array(other)
        @@COUNT.times do |index|
            @values[index] = other[index].to_f()
        end
    end
    
    #このベクトルと引数の足し算を行い結果を格納する
    def add(other)
        @@COUNT.times do |index|
            @values[index] += other[index]
        end
    end
    
    #このベクトルと引数の引き算を行い結果を格納する
    def sub(other)
        @@COUNT.times do |index|
            @values[index] -= other[index]
        end
    end
end
