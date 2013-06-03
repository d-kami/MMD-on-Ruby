class Quaternion
    attr_reader :values
    
    #�e�v�f��index
    @@X = 0
    @@Y = 1
    @@Z = 2
    @@W = 3

    #�N�H�[�^�j�I���̏��������s��
    def initialize(x = 0, y = 0, z = 0, w = 0)
        @values = Array.new()
        set(x, y, z, w)
    end
    
    #������x, y, z, w�����̃N�H�[�^�j�I���Ɋi�[����
    def set(x, y, z, w)
        @values[@@X] = x.to_f()
        @values[@@Y] = y.to_f()
        @values[@@Z] = z.to_f()
        @values[@@W] = w.to_f()
    end
    
    #�����̃N�H�[�^�j�I���������͔z��̒l�����̃N�H�[�^�j�I���Ɋi�[����
    def set_array(other)
        4.times do |index|
            @values[index] = other[index].to_f()
        end
    end
    
    #���̃N�H�[�^�j�I���ƈ����̑����Z���s�����ʂ��i�[����
    def add(other)
        4.times do |index|
            @values[index] += other[index]
        end
    end
    
    #���̃N�H�[�^�j�I���ƈ����̃N�H�[�^�j�I���̊|���Z���s�����ʂ��i�[����
    def mul(other)
        a = self
        b = other
        r = Array.new()
        
        r[@@X] = a[@@W] * b[@@X] + a[@@X] * b[@@W] + a[@@Y] * b[@@Z] - a[@@Z] * b[@@Y]
        r[@@Y] = a[@@W] * b[@@Y] - a[@@X] * b[@@Z] + a[@@Y] * b[@@W] + a[@@Z] * b[@@X]
        r[@@Z] = a[@@W] * b[@@Z] + a[@@X] * b[@@Y] - a[@@Y] * b[@@X] + a[@@Z] * b[@@W]
        r[@@W] = a[@@W] * b[@@W] - a[@@X] * b[@@X] - a[@@Y] * b[@@Y] - a[@@Z] * b[@@Z]
        
        4.times do |index|
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
    
    #���̃N�H�[�^�j�I����w���v�Z����
    def cal_w()
        x = @values[@@X]
        y = @values[@@Y]
        z = @values[@@Z]
        
        @values[@@W] = -Math::sqrt((1.0 - x * x - y * y - z * z).abs())
    end
    
    #index�Ԗڂ̗v�f��Ԃ�
    def [](index)
        return @values[index]
    end
    
    #index�Ԗڂ̗v�f��value������
    def []=(index, value)
        @values[index] = value
    end
    
    #���̃N�H�[�^�j�I���̃m�����̓���Ԃ�
    def norm2()
        ret = 0
        
        4.times do |index|
            ret += @values[index] * @values[index]
        end
        
        return ret
    end
    
    #���̃N�H�[�^�j�I���̃m������Ԃ�
    def norm
        Math.sqrt(norm2())
    end
    
    #�����̃N�H�[�^�j�I���̋t�N�H�[�^�j�I����Ԃ�
    def Quaternion.inverse(quat)
        n = quat.norm2()
        
        return Quaternion.new(-quat[@@X] / n, -quat[@@Y] / n, -quat[@@Z] / n, quat[@@W] / n)
    end
    
    #�����̃N�H�[�^�j�I���̋����N�H�[�^�j�I����Ԃ�
    def Quaternion.conj(quat)
        return Quaternion.new(-quat[@@X], -quat[@@Y], -quat[@@Z], quat[@@W])
    end
end
