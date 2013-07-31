# coding: utf-8

class Quaternion
    attr_reader :values
    
    #各要素のindex
    @@X = 0
    @@Y = 1
    @@Z = 2
    @@W = 3
    
    #要素数
    @@COUNT = 4

    def Quaternion.X
        return @@X
    end
    
    def Quaternion.Y
        return @@Y
    end
    
    def Quaternion.Z
        return @@Z
    end
    
    def Quaternion.W
        return @@W
    end

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
        
        return self
    end
    
    #引数のクォータニオンもしくは配列の値をこのクォータニオンに格納する
    def set_array(other)
        @values[@@X] = other[@@X]
        @values[@@Y] = other[@@Y]
        @values[@@Z] = other[@@Z]
        @values[@@W] = other[@@W]
        
        return self
    end
    
    def set_vector3(other)
        3.times do |i|
            @values[i] = other[i]
        end
        
        return self
    end
    
    #このクォータニオンと引数の足し算を行い結果を格納する
    def add(other)
        @values[@@X] += other[@@X]
        @values[@@Y] += other[@@Y]
        @values[@@Z] += other[@@Z]
        @values[@@W] += other[@@W]
        
        return self
    end
    
    #このクォータニオンと引数のクォータニオンの掛け算を行い結果を格納する
    def mul(other)
        a = self
        b = other
        
        c = a[@@W] * b[@@X] + a[@@X] * b[@@W] + a[@@Y] * b[@@Z] - a[@@Z] * b[@@Y]
        d = a[@@W] * b[@@Y] - a[@@X] * b[@@Z] + a[@@Y] * b[@@W] + a[@@Z] * b[@@X]
        e = a[@@W] * b[@@Z] + a[@@X] * b[@@Y] - a[@@Y] * b[@@X] + a[@@Z] * b[@@W]
        f = a[@@W] * b[@@W] - a[@@X] * b[@@X] - a[@@Y] * b[@@Y] - a[@@Z] * b[@@Z]

        values[@@X] = c
        values[@@Y] = d
        values[@@Z] = e
        values[@@W] = f
        
        return self
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
    
    def normalize()
        length = norm()
        
        self[@@X] /= length
        self[@@Y] /= length
        self[@@Z] /= length
        self[@@W] /= length
    end
    
    def slerp(other, value)
        cosHalfTheta = self[0] * other[0] + self[1] * other[1] + self[2] * other[2] + self[3] * other[3]
        
        if cosHalfTheta.abs() >= 1.0
            return
        end
        
        halfTheta = Math.acos(cosHalfTheta)
        sinHalfTheta = Math.sqrt(1.0 - cosHalfTheta * cosHalfTheta)
        
        if sinHalfTheta.abs() < 0.001
            self[0] = (self[0] * 0.5 + other[0] * 0.5)
            self[1] = (self[1] * 0.5 + other[1] * 0.5)
            self[2] = (self[2] * 0.5 + other[2] * 0.5)
            self[3] = (self[3] * 0.5 + other[3] * 0.5)
            return
        end
        
        
        ratioA = Math.sin((1 - value) * halfTheta) / sinHalfTheta
        ratioB = Math.sin(value * halfTheta) / sinHalfTheta

        self[0] = (self[0] * ratioA + other[0] * ratioB)
        self[1] = (self[1] * ratioA + other[1] * ratioB)
        self[2] = (self[2] * ratioA + other[2] * ratioB)
        self[3] = (self[3] * ratioA + other[3] * ratioB)
    end
    
    #引数のクォータニオンの共役クォータニオンを返す
    def Quaternion.conj(quat)
        return Quaternion.new(-quat[@@X], -quat[@@Y], -quat[@@Z], quat[@@W])
    end
    
    def Quaternion.dot(quat1, quat2)
        return quat1[0] * quat2[0] + quat1[1] * quat2[1] + quat1[2] * quat2[2] + quat1[3] * quat2[3]
    end
end
