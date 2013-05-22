require 'opengl'
require 'glut'
require './mmd.rb'
require './bmp.rb'

class Object3D
    def load_model(file_name)
        File.open(file_name, 'rb'){|file|
            @model = MMDModel.new()
            @model.load(file)
            @textures = Hash.new()
            
            @model.materials.each do |material|
                if material.texture != nil && material.texture.length > 0
                    bitmap = BitMap.read('./model/' + material.texture)
                    image = get_raw(bitmap)
                    
                    @textures[material.texture] = create_texture(image, bitmap.width, bitmap.height)
                end
            end
        }
    end
    
    def get_raw(bitmap)
        image = ''
        
        bitmap.height.times do |y|
            bitmap.width.times do |x|
                rgb = bitmap.pget(x, y)

                index = (y * bitmap.width + x) * 3
                image[index] = rgb[0]
                image[index + 1] = rgb[1]
                image[index + 2] = rgb[2]
            end
        end

        return image
    end
    
    def create_texture(image, width, height)
        texture = GL.GenTextures(1)[0]
        
        GL.BindTexture(GL::TEXTURE_2D, texture)
        GL.TexImage2D(GL::TEXTURE_2D, 0, GL::RGB, width, height, 0, GL::RGB, GL::UNSIGNED_BYTE, image)

        GL.TexParameteri(GL::TEXTURE_2D, GL::TEXTURE_MAG_FILTER, GL::LINEAR)
        GL.TexParameteri(GL::TEXTURE_2D, GL::TEXTURE_MIN_FILTER, GL::LINEAR)
        
        GL.TexParameteri(GL::TEXTURE_2D, GL::TEXTURE_WRAP_S, GL::REPEAT)
        GL.TexParameteri(GL::TEXTURE_2D, GL::TEXTURE_WRAP_T, GL::REPEAT)

        GL.BindTexture(GL::TEXTURE_2D, 0)

        return texture
    end
    
    def init_light()
        @light_diffuse = [1.0, 1.0, 1.0]
        @light_dir = [0.0, 0.0, 1.0]
    end

    def reshape(w,h)
        GL.Viewport(0, 0, w, h)

        GL.MatrixMode(GL::GL_PROJECTION)
        GL.LoadIdentity()
        GLU.Perspective(45.0, w.to_f() / h.to_f(), 0.1, 100.0)
    end

    def display()
        GL.UseProgram(@program)
    
        GL.MatrixMode(GL::GL_MODELVIEW)
        GL.LoadIdentity()
        GLU.LookAt(0.0, 10.0, -27.0, 0.0, 10.0, 0.0, 0.0, 1.0, 0.0)

        GL.ClearColor(0.0, 0.0, 1.0, 1.0)
        GL.Clear(GL::GL_COLOR_BUFFER_BIT | GL::GL_DEPTH_BUFFER_BIT)

        GL.Rotate(@rotX, 1, 0, 0)
        GL.Rotate(@rotY, 0, 1, 0)

        start = 0

        @model.materials.each do |material|
            draw(material, start)
            start += material.vert_count
        end

        GLUT.SwapBuffers()
    end
    
    def draw(material, start)
        GL.Uniform3fv(@locations[:ambient], material.ambient)
        GL.Uniform1f(@locations[:alpha], material.alpha)
        
        useTexture = 0.0

        if material.texture != nil && material.texture.length > 0
            GL.ActiveTexture(GL::TEXTURE0)
            GL.BindTexture(GL::TEXTURE_2D, @textures[material.texture])
            GL.Uniform1i(@locations[:sampler], 0)
            
            useTexture = 1.0
        end
        
        GL.Uniform1f(@locations[:use_texture], useTexture)
        GL.Uniform3fv(@locations[:light_dir], @light_dir)
        GL.Uniform3fv(@locations[:light_diffuse], @light_diffuse)

        GL.Begin(GL::TRIANGLES)
        GL.Color(material.diffuse[0], material.diffuse[1], material.diffuse[2])

        material.vert_count.times do |findex|
            vindex = @model.face.indices[start + findex]
            vertex = @model.vertices[vindex]
            pos = vertex.pos
            normal = vertex.normal
            uv = vertex.uv
            
            GL.TexCoord2f(uv[0], uv[1])
            GL.Normal(normal[0], normal[1], normal[2])
            GL.Vertex(pos[0], pos[1], pos[2])
        end

        GL.End()
        
        GL.BindTexture(GL::TEXTURE_2D, 0)
    end

    def mouse(button, state, x, y)
        if button == GLUT::GLUT_LEFT_BUTTON && state == GLUT::GLUT_DOWN then
            @start_x = x
            @start_y = y
            @drag_flg = true
        elsif state == GLUT::GLUT_UP then
            @drag_flg = false
        end
    end

    def motion(x, y)
        if @drag_flg then
            dx = x - @start_x
            dy = y - @start_y

            @rotY += dx
            @rotY = @rotY % 360

            @rotX -= dy
            @rotX = @rotX % 360
        end
        
        @start_x = x
        @start_y = y
        GLUT.PostRedisplay()
    end

    def initialize()
        @start_x = 0
        @start_y = 0
        @rotY = 0
        @rotX = 0
        @drag_flg = false
        
        GLUT.InitWindowPosition(100, 100)
        GLUT.InitWindowSize(300,300)
        GLUT.Init()
        GLUT.InitDisplayMode(GLUT::GLUT_DOUBLE | GLUT::GLUT_RGB | GLUT::GLUT_DEPTH)
        GLUT.CreateWindow('MMD on Ruby')

        GL.FrontFace(GL::GL_CW)
        GL.Enable(GL::GL_AUTO_NORMAL)
        GL.Enable(GL::GL_NORMALIZE)
        GL.Enable(GL::GL_DEPTH_TEST)
        GL.Enable(GL::TEXTURE_2D)
        GL.DepthFunc(GL::GL_LESS)

        @program = create_program('./shader/mmd.vert', './shader/mmd.frag')
        
        @locations = Hash.new()
        @locations[:alpha] = GL.GetUniformLocation(@program, 'alpha')
        @locations[:ambient] = GL.GetUniformLocation(@program, 'ambient')
        @locations[:sampler] = GL.GetUniformLocation(@program, 'sampler')
        @locations[:use_texture] = GL.GetUniformLocation(@program, 'useTexture')
        @locations[:light_diffuse] = GL.GetUniformLocation(@program, 'lightDiffuse')
        @locations[:light_dir] = GL.GetUniformLocation(@program, 'lightDir')
        
        init_light()

        GLUT.ReshapeFunc(method(:reshape).to_proc())
        GLUT.DisplayFunc(method(:display).to_proc())
        GLUT.MouseFunc(method(:mouse).to_proc())
        GLUT.MotionFunc(method(:motion).to_proc())
        
        load_model('./model/miku.pmd')
    end
    
    def create_program(vert_name, frag_name)
        program = GL.CreateProgram()
        
        vert_shader = create_shader(vert_name, GL_VERTEX_SHADER)
        frag_shader = create_shader(frag_name, GL_FRAGMENT_SHADER)
        
        GL.AttachShader(program, vert_shader)
        GL.AttachShader(program, frag_shader)
        GL.LinkProgram(program)
        
        if !GL.GetProgramiv(program, GL_LINK_STATUS)
            raise(GL.GetProgramInfoLog(program))
        end

        GL.DeleteShader(vert_shader)
        GL.DeleteShader(frag_shader)

        return program
    end

    def create_shader(file_name, type)
        shader = GL.CreateShader(type)
        
        File.open(file_name, 'rb') { |file|
            GL.ShaderSource(shader, file.read())
            GL.CompileShader(shader)
            
            if !GL.GetShaderiv(shader, GL_COMPILE_STATUS)
                raise(GL.GetShaderInfoLog(shader))
            end
        }
        
        return shader
    end

    def start()
        GLUT.MainLoop()
    end
end

Object3D.new().start()
