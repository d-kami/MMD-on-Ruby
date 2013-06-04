# coding: utf-8

class Quaternion
    attr_reader :values
    
    #各要素のindex
    @@X = 0
    @@Y = 1
    @@Z = 2
    @@W = 3
    @@COUNT = 4

    #クォータニオンの初期化を行う
    def initialize(x = 0, y = 0, z = 0, w = 0)
        @values = Array.new()
        set(x, y, z, w)
    end
    
    #引数のx, y, z, wをこのクォータニオンに格納する
    def set(x, y, z, w)
        @values[@@X] = x.to_f()
        @values[@@Y] = y.to_f()
        @values[@@Z] = z.to_f()
        @values[@@W] = w.to_f()
    end
    
    #引数のクォータニオンもしくは配列の値をこのクォータニオンに格納する
    def set_array(other)
        @@COUNT.times do |index|
            @values[index] = other[index].to_f()
        end
    end
    
    #このクォータニオンと引数の足し算を行い結果を格納する
    def add(other)
        @@COUNT.times do |index|
            @values[index] += other[index]
        end
    end
    
    #このクォータニオンと引数のクォータニオンの掛け算を行い結果を格納する
    def mul(other)
        a = self
        b = other
        r = Array.new()
        
        r[@@X] = a[@@W] * b[@@X] + a[@@X] * b[@@W] + a[@@Y] * b[@@Z] - a[@@Z] * b[@@Y]
        r[@@Y] = a[@@W] * b[@@Y] - a[@@X] * b[@@Z] + a[@@Y] * b[@@W] + a[@@Z] * b[@@X]
        r[@@Z] = a[@@W] * b[@@Z] + a[@@X] * b[@@Y] - a[@@Y] * b[@@X] + a[@@Z] * b[@@W]
        r[@@W] = a[@@W] * b[@@W] - a[@@X] * b[@@X] - a[@@Y] * b[@@Y] - a[@@Z] * b[@@Z]
        
        @@COUNT.times do |index|
            @values[index] = r[index]
        end
    end
    
    def mul_vec3(vec3)
        x = vec[0]
        y = vec[1]
        z = vec[2]
        
        qx = @values[@@X]
        qy = @values[@@Y]
        qz = @values[@@Z]
        qw = @values[@@W]

        ix = qw * x + qy * z - qz * y
        iy = qw * y + qz * x - qx * z
        iz = qw * z + qx * y - qy * x
        iw = -qx * x - qy * y - qz * z

        result = Array.new()
        result[0] = ix * qw + iw * -qx + iy * -qz - iz * -qy;
        result[1] = iy * qw + iw * -qy + iz * -qx - ix * -qz;
        result[2] = iz * qw + iw * -qz + ix * -qy - iy * -qx;
        
        return result
    end
    
    #このクォータニオンのwを計算する
    def cal_w()
        x = @values[@@X]
        y = @values[@@Y]
        z = @values[@@Z]
        
        @values[@@W] = -Math::sqrt((1.0 - x * x - y * y - z * z).abs())
    end
    
    #index番目の要素を返す
    def [](index)
        return @values[index]
    end
    
    #index番目の要素にvalueを入れる
    def []=(index, value)
        @values[index] = value
    end
    
    #このクォータニオンのノルムの二乗を返す
    def norm2()
        ret = 0
        
        @@COUNT.times do |index|
            ret += @values[index] * @values[index]
        end
        
        return ret
    end
    
    #このクォータニオンのノルムを返す
    def norm
        Math.sqrt(norm2())
    end
    
    #引数のクォータニオンの逆クォータニオンを返す
    def Quaternion.inverse(quat)
        n = quat.norm2()
        
        return Quaternion.new(-quat[@@X] / n, -quat[@@Y] / n, -quat[@@Z] / n, quat[@@W] / n)
    end
    
    #引数のクォータニオンの共役クォータニオンを返す
    def Quaternion.conj(quat)
        return Quaternion.new(-quat[@@X], -quat[@@Y], -quat[@@Z], quat[@@W])
    end
end
