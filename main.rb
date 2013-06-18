# coding: utf-8

require 'opengl'
require 'glut'
require './lib/mmd.rb'
require './lib/motion.rb'
require './lib/shader.rb'
require './lib/load_image.rb'
require './lib/init_buffers.rb'

#読み込むモデルファイルのファイル名
model_file = 'mikumetal.pmd'

#読み込むモーションファイルのファイル名
motion_file = 'kishimen.vmd'

#読み込む頂点シェーダとフラグメントシェーダ
shader_file = ['mmd.vert', 'mmd.frag']

class Object3D
    include Shader
    include LoadImage
    include InitBuffers

    #MMDのモデルファイルを読み込む
    def load_model(file_name)
        File.open(file_name, 'rb'){|file|
            @model = MMDModel.new()
            @model.load(file)
            @textures = Hash.new()

            #マテリアルごとにスフィアマップ画像、テクスチャ画像を読み込む
            @model.materials.each do |material|
                load_sphere(material, @textures)
                load_texture(material, @textures)
            end

            @buffers = init_buffers(@model)

            #toonファイル名を設定し読み込む
            @toons = create_toons(@model)
            load_toons(@toons, @textures)
            
            #表情を連想配列で管理するように設定する
            set_skins()
        }
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
        
        send_attributes(@buffers, @locations)

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
        GL.DrawElements(GL::TRIANGLES, material.vert_count, GL::UNSIGNED_SHORT, start * 2)
        
        #テクスチャ解除
        GL.BindTexture(GL::TEXTURE_2D, 0)
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
    def load(model_name, motion_name, vertex_shader, fragment_shader)
        load_model("./model/#{model_name}")
        load_motion("./motion/#{motion_name}")
        
        @program, @locations = load_shader(vertex_shader, fragment_shader)
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
object.load(model_file, motion_file, shader_file[0], shader_file[1])
object.set_func()

object.start()
