# coding: utf-8

require './lib/math/quat.rb'

class Vector3
    attr_reader :values

    #各要素のindex
    @@X = 0
    @@Y = 1
    @@Z = 2
    
    #要素数
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
        @values[@@X] = x.to_f()
        @values[@@Y] = y.to_f()
        @values[@@Z] = z.to_f()
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
    
    #このベクトルをval倍する
    def scale(val)
        @@COUNT.times do |index|
            @values[index] *= val
        end
    end
    
    #このベクトルのノルムの二乗を返す
    def norm2()
        ret = 0
        
        @@COUNT.times do |index|
            ret += @values[index] * @values[index]
        end
        
        return ret
    end

    #このベクトルのノルムを返す
    def norm
        Math.sqrt(norm2())
    end
    
    #このベクトルを正規化する
    def normalize()
        length = norm
        
        @@COUNT.times do |index|
            @values[index] /= norm
        end
    end
    
    def Vector3.dot(vec, vec2)
        return vec[0] * vec2[0] + vec[1] * vec2[1] + vec[2] * vec2[2]
    end
    
    def Vector3.cross(vec, vec2)
        result = Vector3.new()

        result[0] = vec[1] * vec2[2] - vec[2] * vec2[1]
        result[1] = vec[2] * vec2[0] - vec[0] * vec2[2]
        result[2] = vec[0] * vec2[1] - vec[1] * vec2[0]

        return result
    end
    
    #引数のベクトルをクォータニオンを使って回転させる
    def Vector3.rotateByQuat(vec, quat)
        x = vec[0]
        y = vec[1]
        z = vec[2]
        
        qx = quat[0]
        qy = quat[1]
        qz = quat[2]
        qw = quat[3]

        ix = qw * x + qy * z - qz * y
        iy = qw * y + qz * x - qx * z
        iz = qw * z + qx * y - qy * x
        iw = -qx * x - qy * y - qz * z

        result = Vector3.new()
        result[0] = ix * qw + iw * -qx + iy * -qz - iz * -qy
        result[1] = iy * qw + iw * -qy + iz * -qx - ix * -qz
        result[2] = iz * qw + iw * -qz + ix * -qy - iy * -qx
        
        return result
    end
end
