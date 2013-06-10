# coding: utf-8

require 'opengl'
require 'glut'
require './lib/mmd.rb'
require './lib/motion.rb'
require './lib/image/bmp.rb'
require './lib/image/pureimage.rb'

#読み込むモデルファイルのファイル名
model_file = 'mikumetal.pmd'

#読み込むモーションファイルのファイル名
motion_file = 'kishimen.vmd'

#読み込む頂点シェーダとフラグメントシェーダ
shader_file = ['mmd.vert', 'mmd.frag']

class Object3D

    #toonファイルの名前を配列にセットする
    def set_toon_names()
        @toons = Array.new()
        
        #toon_indexが-1のときのtoonファイル
        @toons[10] = 'toon00.bmp'
    
        if @model.toon_texture == nil
            #toonファイルの名前に指定が無い場合はデフォルトのファイル名を使う
            10.times do |index|
                @toons[index] = get_default_toon(index)
            end
        else
            10.times do |index|
                if @model.toon_texture.names[index] != nil && @model.toon_texture.names[index].end_with?('.bmp')
                    #toonファイルの名前に指定がある
                    @toons[index] = @model.toon_texture.names[index]
                else
                    #toonファイルの名前に指定が無いのでデフォルトのファイル名を使う
                    @toons[index] = get_default_toon(index)
                end
            end
        end
    end
    
    #index番目のデフォルトのファイル名を返す
    def get_default_toon(index)
        if index == 9
            return "toon#{index + 1}.bmp"
        else
            return "toon0#{index + 1}.bmp"
        end
    end

    #toonファイルを読み込み、テクスチャとして設定する
    def load_toons()
        @toons.length.times do |index|
            bitmap = BitMap.read("./toon/#{@toons[index]}")
            image = get_raw(bitmap)

            @textures[@toons[index]] = create_texture(image, bitmap.width, bitmap.height)
        end
    end
    
    #bmpを読み込み、テクスチャにして返す
    def load_bmp(file_name)
        bitmap = BitMap.read(file_name)
        image = get_raw(bitmap)
        return create_texture(image, bitmap.width, bitmap.height)
    end
    
    #スフィアマップ用のテクスチャを読み込み設定する
    def load_sphere(material)
        if material.sphere != nil && !@textures.key?(material.sphere)
            @textures[material.sphere] = load_bmp("./model/#{material.sphere}")
        end
    end
    
    #マテリアルに設定されているテクスチャを読み込む
    def load_texture(material)
        if material.texture != nil && !@textures.key?(material.texture)
            #読み込むテクスチャが存在していて、まだ登録されてない場合の処理
            
            if material.texture.end_with?('.bmp')
                #bmpファイルをテクスチャとする
                @textures[material.texture] = load_bmp("./model/#{material.texture}")
            elsif material.texture.end_with?('.png')
                pngio = PureImage::PNGIO.new()
                png = pngio.load("./model/#{material.texture}")
                image = get_raw_png(png)
                #pngファイルをテクスチャとする
                @textures[material.texture] = create_texture(image, png.width, png.height)
            end
        end
    end

    #bitmapからRGB配列を取得する
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
    
    #pngからRGB配列を取得する
    def get_raw_png(png)
        image = ''
        
        png.height.times do |y|
            png.width.times do |x|
                rgb = png.get(x, y)

                index = (y * png.width + x) * 3
                image[index] = [rgb[0]].pack('C')
                image[index + 1] = [rgb[2]].pack('C')
                image[index + 2] = [rgb[1]].pack('C')
            end
        end

        return image
    end
    
    #テクスチャを作成して返す
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

    #MMDのモデルファイルを読み込む
    def load_model(file_name)
        File.open(file_name, 'rb'){|file|
            @model = MMDModel.new()
            @model.load(file)
            @textures = Hash.new()

            #マテリアルごとにスフィアマップ画像、テクスチャ画像を読み込む
            @model.materials.each do |material|
                load_sphere(material)
                load_texture(material)
            end

            init_vertices()
            init_vertex_info()

            #toonファイル名を設定し読み込む
            set_toon_names()
            load_toons()
            
            #表情を連想配列で管理するように設定する
            set_skins()
        }
    end
    
    def init_vertices()
        weight = Array.new()
        vectors1 = Array.new()
        vectors2 = Array.new()
        positions1 = Array.new()
        positions2 = Array.new()
        rotations1 = Array.new()
        rotations2 = Array.new()

        @model.vertices.length.times do |i|
            vertex = @model.vertices[i]
            bone1 = @model.bones[vertex.bone_nums[0]]
            bone2 = @model.bones[vertex.bone_nums[1]]
            weight[i] = vertex.bone_weight
            
            3.times do |j|
                vectors1[3 * i + j] = vertex.pos[j] - bone1.pos[j]
                vectors2[3 * i + j] = vertex.pos[j] - bone2.pos[j]
                positions1[3 * i + j] = bone1.pos[j]
                positions2[3 * i + j] = bone2.pos[j]
                rotations1[4 * i + j] = 0.0
                rotations2[4 * i + j] = 0.0
            end
            
            rotations1[4 * i + 3] = 1.0
            rotations2[4 * i + 3] = 1.0
        end
        
        @buffers = Hash.new()
        @buffers[:bone_weight] = create_buffer(weight)
        @buffers[:vector_from_bone1] = create_buffer(vectors1)
        @buffers[:vector_from_bone2] = create_buffer(vectors2)
        @buffers[:bone1_rotation] = create_buffer(rotations1)
        @buffers[:bone2_rotation] = create_buffer(rotations2)
        @buffers[:bone1_position] = create_buffer(positions1)
        @buffers[:bone2_position] = create_buffer(positions2)
        
        indexBuffer = GL.GenBuffers(1)[0]
        GL.BindBuffer(GL::ELEMENT_ARRAY_BUFFER, indexBuffer)
        GL.BufferData(GL::ELEMENT_ARRAY_BUFFER, @model.face.indices.length * 2, @model.face.indices.pack('v*'), GL_STATIC_DRAW);
        @buffers[:indices] = indexBuffer
    end
    
    def init_vertex_info()
        normals = Array.new()
        texcoords = Array.new()

        @model.vertices.length.times{|index|
            normals[index] = @model.vertices[index].normal
            texcoords[index] = @model.vertices[index].uv
        }
        
        @buffers[:normal] = create_buffer(normals.flatten())
        @buffers[:texcoord] = create_buffer(texcoords.flatten())
    end
    
    def create_buffer(array)
        buffer = GL.GenBuffers(1)[0]
        GL.BindBuffer(GL::ARRAY_BUFFER, buffer)
        GL.BufferData(GL::ARRAY_BUFFER, 4 * array.size, array.pack('f*'), GL_STATIC_DRAW)

        return buffer
    end
    
    #表情を連想配列で管理するように設定する
    def set_skins()
        @skin_map = Hash.new()
    
        @model.skins.each{|skin|
            @skin_map[skin.name] = skin
        }
    end
    
    #MMDのモーションファイル(VMD)を読み込む
    def load_motion(file_name)
        File.open(file_name, 'rb'){|file|
            @motion = MMDMotion.new()
            @motion.load(file)
            
            @skin_index = 0
            @frame = 0
        }
    end
    
    #光源の色と方向設定
    def init_light()
        @light_diffuse = [1.0, 1.0, 1.0]
        @light_dir = [0.5, 1.0, 0.5]
    end
    
    def move_bones(bones)
        indivisualBoneMotions = Array.new()
        boneMotions = Array.new()

        @model.bones.each_with_index do |bone, index|
        end
    end
    
    def resolve_iks(model)
        target = Vector3.new()
        ikbone = Vector3.new()
        axis = Vector3.new()
        
        tmpQ = Quaternion.new()
        tmpR = Quaternion.new()
        
        model.iks.each do |ik|
            maxangle = ik.weight * 4
        end
    end

    #描画領域のサイズの変更
    def reshape(w,h)
        GL.Viewport(0, 0, w, h)

        GL.MatrixMode(GL::GL_PROJECTION)
        GL.LoadIdentity()
        GLU.Perspective(45.0, w.to_f() / h.to_f(), 0.1, 100.0)
    end
    
    #表情の変更を行う
    def skin_motions()
        while @skin_index < @motion.skins.length && @motion.skins[@skin_index].flame_no == @frame
            #@frameと一致しているflame_noを持つ表情を全て設定する
            skin_motion()

            @skin_index += 1
        end
    end
    
    #表情の変更を行う
    def skin_motion()
        #モデルに登録されてない表情は無視する
        if !@skin_map.key?(@motion.skins[@skin_index].name)
            return
        end

        skin = @skin_map[@motion.skins[@skin_index].name]

        if skin.name == 'base'
            #デフォルトの表情
            skin.vertices.each do |base|
                3.times{|i|
                    @model.vertices[base.index].pos[i] = base.pos[i]
                }
            end
        else
            #変更する表情
            skin.vertices.each do |vertex|
                base = @model.skins[0].vertices[vertex.index]

                3.times{|i|
                     @model.vertices[base.index].pos[i] = base.pos[i] + vertex.pos[i] * @motion.skins[@skin_index].weight
                }
            end
        end
    end

    #モデル情報の更新を行う
    def update_motion()
        skin_motions()
    end

    #3D画面の描画を行う
    def display()
        GL.UseProgram(@program)

        #カメラの設定
        GL.MatrixMode(GL::GL_MODELVIEW)
        GL.LoadIdentity()
        GLU.LookAt(0.0, 0.0, 37.0, 0.0, 10.0, 0.0, 0.0, 1.0, 0.0)

        #背景色の設定
        GL.ClearColor(0.0, 0.0, 1.0, 1.0)
        GL.Clear(GL::GL_COLOR_BUFFER_BIT | GL::GL_DEPTH_BUFFER_BIT)

        #モデルの回転
        GL.Rotate(@rotX, 1, 0, 0)
        GL.Rotate(@rotY, 0, 1, 0)

        #カリングを有効にする
        GL.Enable(GL::CULL_FACE)
        
        send_attributes()

        #モデル描画
        draw_model()
        
        #エッジ描画
        draw_edge()
        
        GLUT.SwapBuffers()
    end
    
    #モデル描画
    def draw_model()
        GL.CullFace(GL::BACK)
        GL.Uniform1i(@locations[:is_edge], 0)

        GL.Enable(GL::DEPTH_TEST)
        GL.DepthFunc(GL::LEQUAL)
        
        #アルファブレンドを有効にする
        GL.Enable(GL::BLEND)
        GL.BlendFuncSeparate(GL::SRC_ALPHA, GL::ONE_MINUS_SRC_ALPHA, GL::SRC_ALPHA, GL::DST_ALPHA)

        #マテリアルの開始番号
        start = 0

        #マテリアルを1つずつ描画する
        @model.materials.each do |material|
            #モデルの一部分を描画する
            draw_part(material, start)
            start += material.vert_count
        end
    end
    
    #エッジを描画する
    def draw_edge()
        #アルファブレンドを無効にする
        GL.Disable(GL::BLEND)
        GL.CullFace(GL::FRONT)
        GL.Uniform1i(@locations[:is_edge], 1)

        #マテリアルの開始番号
        start = 0

        @model.materials.each do |material|
            #エッジとなるマテリアルのみ描画する
            if(material.edge_flag)
                #モデルの一部分を描画する
                draw_part(material, start)
            end
            
            start += material.vert_count
        end
    end
    
    #モデルの一部分を描画する
    def draw_part(material, start)
        #テクスチャの準備、設定
        prepare_texture(material)
        
        #スフィアマップの準備、設定
        prepare_sphere(material)
        
        #toonテクスチャの準備、設定
        prepare_toon(material)
        
        #materialの設定
        prepare_material(material)
        
        #光源の設定
        prepare_light()
        
        #マテリアルの描画
        draw_material(material, start)
    end
    
    #テクスチャの準備、設定
    def prepare_texture(material)
        useTexture = 0
    
        if material.texture != nil && material.texture.length > 0
            #マテリアルに貼るテクスチャがある場合はテクスチャ情報をシェーダに渡す
            GL.ActiveTexture(GL::TEXTURE0)
            GL.BindTexture(GL::TEXTURE_2D, @textures[material.texture])
            GL.Uniform1i(@locations[:sampler], 0)
            
            useTexture = 1
        end
        
        GL.Uniform1i(@locations[:use_texture], useTexture)
    end
    
    #スフィアマップの準備、設定
    def prepare_sphere(material)
        if material.sphere != nil && material.sphere.length > 0
            #マテリアルに貼るスフィアマップ用テクスチャがある場合はスフィアマップ用テクスチャ情報をシェーダに渡す
            GL.ActiveTexture(GL::TEXTURE2)
            GL.BindTexture(GL::TEXTURE_2D, @textures[material.sphere])
            GL.Uniform1i(@locations[:is_sphere_use], 1)
            GL.Uniform1i(@locations[:sphere_sampler], 2)
            
            #スフィアマップの設定。1なら加算、0なら乗算
            if material.sphere.end_with?('.spa')
                GL.Uniform1i(@locations[:is_sphere_add], 1)
            else
                GL.Uniform1i(@locations[:is_sphere_add], 0)
            end
        else
            GL.Uniform1i(@locations[:is_sphere_use], 0)
        end
    end

    #toonテクスチャの準備、設定
    def prepare_toon(material)
        toon_index = material.toon_index

        if toon_index == 255
            toon_index = 10
        end

        #toonテクスチャの情報をシェーダに渡す
        GL.ActiveTexture(GL::TEXTURE1)
        GL.BindTexture(GL::TEXTURE_2D, @textures[@toons[toon_index]])
        GL.Uniform1i(@locations[:toon_sampler], 1)
    end
    
    #materialの設定
    def prepare_material(material)
        GL.Uniform1f(@locations[:alpha], material.alpha)
        GL.Uniform3fv(@locations[:ambient], material.ambient)
        GL.Uniform1f(@locations[:shininess], material.specularity)
        GL.Uniform3fv(@locations[:specular_color], material.specular)
        GL.Uniform3fv(@locations[:diffuse], material.diffuse)
    end
    
    #光源の設定
    def prepare_light
        GL.Uniform3fv(@locations[:light_dir], @light_dir)
        GL.Uniform3fv(@locations[:light_diffuse], @light_diffuse)
    end

    #マテリアルの描画
    def draw_material(material, start)
        GL.BindBuffer(GL::ELEMENT_ARRAY_BUFFER, @buffers[:indices])
        GL.DrawElements(GL::TRIANGLES, material.vert_count, GL::UNSIGNED_SHORT, start * 2);
        
        #テクスチャ解除
        GL.BindTexture(GL::TEXTURE_2D, 0)
    end
    
    def send_attributes()
        send_attribute(:bone_weight, 1)
        send_attribute(:vector_from_bone1, 3)
        send_attribute(:vector_from_bone2, 3)
        send_attribute(:bone1_rotation, 4)
        send_attribute(:bone2_rotation, 4)
        send_attribute(:bone1_position, 3)
        send_attribute(:bone2_position, 3)
        send_attribute(:normal, 3)
        send_attribute(:texcoord, 2)
    end
    
    def send_attribute(label, size)
        GL.BindBuffer(GL_ARRAY_BUFFER, @buffers[label])
        GL.VertexAttribPointer(@locations[label], size, GL_FLOAT, false, 0, 0)
    end

    #マウスのボタンが押されたときと離されたときのイベント
    def mouse(button, state, x, y)
        if button == GLUT::GLUT_LEFT_BUTTON && state == GLUT::GLUT_DOWN then
            @start_x = x
            @start_y = y
            @drag_flg = true
        elsif state == GLUT::GLUT_UP then
            @drag_flg = false
        end
    end

    #マウスを移動したときのイベント
    def motion(x, y)
        #ドラッグ中なら、モデルを回転する
        if @drag_flg then
            dx = x - @start_x
            dy = y - @start_y

            @rotY += dx
            @rotY = @rotY % 360

            @rotX += dy
            @rotX = @rotX % 360
        end
        
        @start_x = x
        @start_y = y
        GLUT.PostRedisplay()
    end

    #1フレームごとに呼び出されるメソッド
    def update(value)
        GLUT.TimerFunc(33 , method(:update).to_proc(), 0)
        
        update_motion()
        
        #再描画要求
        GLUT.PostRedisplay()
        
        @frame += 1
    end

    #初期化
    def initialize()
        @start_x = 0
        @start_y = 0
        @rotY = 0
        @rotX = 0
        @drag_flg = false
        
        init_light()
    end
    
    #モデルとモーションの読み込み
    def load(model_name, motion_name)
        load_model("./model/#{model_name}")
        load_motion("./motion/#{motion_name}")
    end
    
    #シェーダの読み込み、コンパイル、Uniform変数へのリンク
    def load_shader(vert_shader, frag_shader)
        @program = create_program("./shader/#{vert_shader}", "./shader/#{frag_shader}")
        
        @locations = Hash.new()
        @locations[:is_edge] = GL.GetUniformLocation(@program, 'isEdge')
        @locations[:alpha] = GL.GetUniformLocation(@program, 'alpha')
        @locations[:ambient] = GL.GetUniformLocation(@program, 'ambient')
        @locations[:sampler] = GL.GetUniformLocation(@program, 'sampler')
        @locations[:toon_sampler] = GL.GetUniformLocation(@program, 'toonSampler')
        @locations[:use_texture] = GL.GetUniformLocation(@program, 'useTexture')
        @locations[:light_diffuse] = GL.GetUniformLocation(@program, 'lightDiffuse')
        @locations[:light_dir] = GL.GetUniformLocation(@program, 'lightDir')
        @locations[:shininess] = GL.GetUniformLocation(@program, 'shininess')
        @locations[:specular_color] = GL.GetUniformLocation(@program, 'supecularColor')
        @locations[:diffuse] = GL.GetUniformLocation(@program, 'diffuse')
        @locations[:is_sphere_use] = GL.GetUniformLocation(@program, 'isSphereUse')
        @locations[:is_sphere_add] = GL.GetUniformLocation(@program, 'isSphereAdd')
        @locations[:sphere_sampler] = GL.GetUniformLocation(@program, 'sphereSampler')
        
        attribute(:bone_weight, 'boneWeight')
        attribute(:vector_from_bone1, 'vectorFromBone1')
        attribute(:vector_from_bone2, 'vectorFromBone2')
        attribute(:bone1_rotation, 'bone1Rotation')
        attribute(:bone2_rotation, 'bone2Rotation')
        attribute(:bone1_position, 'bone1Position')
        attribute(:bone2_position, 'bone2Position')
        attribute(:normal, 'vertNormal')
        attribute(:texcoord, 'texCoord')
    end
    
    def attribute(label, name)
        @locations[label] = GL.GetAttribLocation(@program, name)
        GL.EnableVertexAttribArray(@locations[label])
    end
    
    #シェーダをコンパイルして、リンクする
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

    #シェーダのコンパイルする
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
    
    #OpenGL用のパラメータを設定
    def set_gl_parameter()
        GL.Enable(GL::TEXTURE_2D)
        GL.Enable(GL::GL_DEPTH_TEST)
        GL.DepthFunc(GL::GL_LESS)
    end
    
    #GLUTでの初期化
    def create_window(x, y, width, height, title)
        GLUT.InitWindowPosition(x, y)
        GLUT.InitWindowSize(width, height)
        GLUT.Init()
        GLUT.InitDisplayMode(GLUT::GLUT_DOUBLE | GLUT::GLUT_RGB | GLUT::GLUT_DEPTH)
        GLUT.CreateWindow(title)
    end
    
    #イベントとメソッドを関連付ける
    def set_func()
        GLUT.ReshapeFunc(method(:reshape).to_proc())
        GLUT.DisplayFunc(method(:display).to_proc())
        GLUT.MouseFunc(method(:mouse).to_proc())
        GLUT.MotionFunc(method(:motion).to_proc())
        GLUT.TimerFunc(33 , method(:update).to_proc(), 0)
    end

    def start()
        GLUT.MainLoop()
    end
end

object = Object3D.new()
object.create_window(100, 100, 450, 450, 'MMD on Ruby')
object.set_gl_parameter()

object.load(model_file, motion_file)
object.load_shader(shader_file[0], shader_file[1])

object.set_func()
object.start()
