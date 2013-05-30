class Quaternion
    attr_reader :values

    def initialize(x = 0, y = 0, z = 0, w = 0)
        @values = Array.new()
        set(x, y, z, w)
    end
    
    def set(x, y, z, w)
        @values[0] = x.to_f()
        @values[1] = y.to_f()
        @values[2] = z.to_f()
        @values[3] = w.to_f()
    end
    
    def set_array(other)
        4.times do |index|
            @values[index] = other[index].to_f()
        end
    end
    
    def add(other)
        4.times do |index|
            @values[index] += other[index]
        end
    end
    
    def mul(other)
        a = self
        b = other
        r = Array.new()
        
        r[0] = a[0] * b[0] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3]
        r[1] = a[0] * b[1] + a[1] * b[0] + a[2] * b[3] - a[3] * b[2]
        r[2] = a[0] * b[2] - a[1] * b[3] + a[2] * b[0] + a[3] * b[1]
        r[3] = a[0] * b[3] + a[1] * b[2] - a[2] * b[1] + a[3] * b[0]
        
        4.times do |index|
            @values[index] = r[index]
        end
    end
    
    
    
    def cal_w()
        x = @values[0]
        y = @values[1]
        z = @values[2]
        
        @values[3] = -Math::sqrt((1.0 - x * x - y * y - z * z).abs())
    end
    
    def [](index)
        return @values[index]
    end
    
    def []=(index, value)
        @values[index] = value
    end
    
    def norm2()
        ret = 0
        
        4.times do |index|
            ret += @values[index] * @values[index]
        end
        
        return ret
    end
    
    def length
        Math.sqrt(norm2())
    end
    
    def Quaternion.inverse(quat)
        n = quat.norm2()
        
        return Quaternion.new(quat[0] / n, -quat[1] / n, -quat[2] / n, -quat[3] / n)
    end
    
    def Quaternion.conj(quat)
        return Quaternion.new(quat[0], -quat[1], -quat[2], -quat[3])
    end
end
