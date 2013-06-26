# coding: utf-8

require 'opengl'
require 'glut'

require 'narray'

require './lib/mmd.rb'
require './lib/motion.rb'
require './lib/shader.rb'
require './lib/load_image.rb'
require './lib/init_buffers.rb'

require './lib/math/vec3.rb'
require './lib/math/quat.rb'

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
    
    @@ONE = [0.0, 0.0, 0.0, 1.0]

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
            
            set_bones()
            
            #表情を連想配列で管理するように設定する
            set_skins()
        }
    end
    
    def set_bones()
        @bone_map = Hash.new()
        
        @model.bones.each do |bone|
            @bone_map[bone.name] = bone
        end
    end
    
    #表情を連想配列で管理するように設定する
    def set_skins()
        @skin_map = Hash.new()
    
        @model.skins.each do |skin|
            @skin_map[skin.name] = skin
        end
    end
    
    #MMDのモーションファイル(VMD)を読み込む
    def load_motion(file_name)
        File.open(file_name, 'rb'){|file|
            @motion = MMDMotion.new()
            @motion.load(file)
            
            add_motions(@motion.motions)
            
            @bone_index = 0
            @skin_index = 0
            @frame = 0
        }
    end
    
    #motion_mapを作成しmotionsの要素を追加していく
    def add_motions(motions)
        @motion_map = Hash.new()
    
        motions.each do |motion|
            add_motion(@motion_map, motion)
        end
        
        @motion_map.each do |key, value|
            value.sort! do |a, b|
                a.flame_no <=> b.flame_no
            end
        end
    end
    
    #motion_mapにmotionを追加する
    def add_motion(motion_map, motion)
        name = motion.bone_name
    
        if !@motion_map.key?(name)
            motion_map[name] = Array.new()
        end
        
        motion_map[name].push(motion)
    end
    
    #光源の色と方向設定
    def init_light()
        @light_diffuse = [1.0, 1.0, 1.0]
        @light_dir = [0.5, 1.0, 0.5]
    end
    
    def resolve_iks()
        target_vec = Vector3.new()
        ikbone_vec = Vector3.new()
        axis = Vector3.new()
        tmp_q = Quaternion.new()
        tmp_r = Quaternion.new()
        
        @model.iks.each do |ik|
            ikbone_pos = move_bone(ik.bone_index).apos
            target_index = ik.target_index
            axis.set_array(@model.bones[target_index].pos).sub(@model.bones[@model.bones[target_index].parent_index].pos)
            min_length = 0.1 * axis.norm()
            
            ik.iterations.times do |n|
                target_pos = move_bone(target_index).apos
                
                if min_length > axis.set_array(target_pos).sub(ikbone_pos).norm()
                    break
                end

                ik.children.each_with_index do |bone_index, i|
                    motion = move_bone(bone_index)
                    bone_pos = motion.apos
                    target_pos = move_bone(target_index).apos if i > 0

                    target_vec.set_array(target_pos).sub(bone_pos)
                    target_vec_len = target_vec.norm()
                    next if target_vec_len < min_length

                    ikbone_vec.set_array(ikbone_pos).sub(bone_pos)
                    ikbone_vec_len = ikbone_vec.norm()
                    next if ikbone_vec_len < min_length
                    
                    axis = Vector3.cross(target_vec, ikbone_vec)
                    axis_len = axis.norm()
                    sin_theta = axis_len / ikbone_vec_len / target_vec_len
                    next if sin_theta < 0.001
                    
                    max_angle = (i + 1) * ik.weight * 4
                    theta = Math.asin(sin_theta)
                    theta = 3.141592653589793 - theta if Vector3.dot(target_vec, ikbone_vec) < 0
                    theta = max_angle if theta > max_angle
                    
                    tmp_q.set_vector3(axis.scale(Math.sin(theta / 2) / axis_len))
                    tmp_q[3] = Math.cos(theta / 2)
                    
                    parent_rotation = move_bone(@model.bones[bone_index].parent_index).arot
                    r = Quaternion.inverse(parent_rotation)
                    r.mul(tmp_q).mul(motion.arot)

                    r.normalize()
                    @model.bones[bone_index].mrot.set_array(r)
                    motion.arot.mul(tmp_q)
                    
                    i.times do |j|
                        @model.bones[j].visited = false
                    end
                    
                    @model.bones[ik.target_index].visited = false
                end
            end
        end
    end
    
    def move_bone(index)
        bone = @model.bones[index]

        if bone.visited
            return bone
        end

        if bone.parent_index == -1
            bone.apos.set_array(bone.pos)
            bone.apos.add(bone.mpos)
            bone.arot.set_array(bone.mrot)
            return bone
        else
            parent = move_bone(bone.parent_index)
            
            bone.apos[0] = bone.pos[0] - parent.pos[0] + bone.mpos[0]
            bone.apos[1] = bone.pos[1] - parent.pos[1] + bone.mpos[1]
            bone.apos[2] = bone.pos[2] - parent.pos[2] + bone.mpos[2]

            bone.apos.rotate_by_quat(parent.arot)
            
            bone.apos[0] += parent.apos[0]
            bone.apos[1] += parent.apos[1]
            bone.apos[2] += parent.apos[2]

            bone.arot.set_array(parent.arot)
            
            if (bone.mrot.values <=> @@ONE) != 0
                bone.arot.mul(bone.mrot)
            end
            
            bone.visited = true
            
            return bone
        end
    end
    
    def bone_motions()
        start = Time.now()

        @motion_map.each do |name, motions|
            bone_motion(name, motions, @frame)
        end

        @model.bones.each do |bone|
            bone.apos.set(0.0, 0.0, 0.0)
            bone.arot.set(0.0, 0.0, 0.0, 1.0)
            bone.visited = false
        end
        
        #resolve_iks()

        @model.bones.length.times do |i|
            move_bone(i)
        end
        
        bpos = NArray.to_na(@model.bones.map{|b| b.apos.values}).flatten().to_type(NArray::SFLOAT)
        brot = NArray.to_na(@model.bones.map{|b| b.arot.values}).flatten().to_type(NArray::SFLOAT)
        bnum1 = NArray.to_na(@model.vertices.map{|v| v.bone_nums[0]}).flatten
        bnum2 = NArray.to_na(@model.vertices.map{|v| v.bone_nums[1]}).flatten
        
        @positions1 = bpos[NArray.refer(bnum1 * NVector[3, 3, 3] + NVector[0, 1, 2]).flatten()].to_s()
        @positions2 = bpos[NArray.refer(bnum2 * NVector[3, 3, 3] + NVector[0, 1, 2]).flatten()].to_s()
        @rotations1 = brot[NArray.refer(bnum1 * NVector[4, 4, 4, 4] + NVector[0, 1, 2, 3]).flatten()].to_s()
        @rotations2 = brot[NArray.refer(bnum2 * NVector[4, 4, 4, 4] + NVector[0, 1, 2, 3]).flatten()].to_s()
        
        modify_buffer(@buffers[:bone1_position], @positions1)
        modify_buffer(@buffers[:bone2_position], @positions2)
        
        modify_buffer(@buffers[:bone1_rotation], @rotations1)
        modify_buffer(@buffers[:bone2_rotation], @rotations2)

        endm = Time.now()
        puts (endm - start).to_s() + "s"
    end
    
    def bone_motion(name, motions, frame)
        #モデルに登録されてないボーンは無視する
        if !@bone_map.key?(name)
            return
        end
        
        index = bsearch(motions, frame)
        motion = motions[index]
        
        if index + 1 < motions.length
            nextm = motions[index + 1]
        else
            nextm = motion
        end

        bone = @bone_map[motion.bone_name]
        
        if(motion.flame_no == nextm.flame_no)
            per = 1.0;
        else
            if(frame >= motion.flame_no)
                per = (frame - motion.flame_no).to_f() / (nextm.flame_no - motion.flame_no)
            else
                per = 1.0
            end
        end
        
        bone.mpos.set_array(motion.location)
        lerp3 = [bezie(nextm, 0, per), bezie(nextm, 1, per), bezie(nextm, 2, per)]
        bone.mpos.lerp3(nextm.location, lerp3)

        if Quaternion.dot(motion.rotation, nextm.rotation) >= 0
            bone.mrot.set_array(motion.rotation)
            bone.mrot.slerp(nextm.rotation, bezie(nextm, 3, per))
        else
            bone.mrot.set(-motion.rotation[0], -motion.rotation[1], -motion.rotation[2], -motion.rotation[3])
            bone.mrot.slerp(nextm.rotation, bezie(nextm, 3, per))
        end
    end
    
    def bsearch(motions, frame)
        low = 0
        high = motions.size - 1

        while low <= high
            mid = (low + high) / 2

            if frame == motions[mid].flame_no
                return mid
            elsif frame > motions[mid].flame_no
                low = mid + 1
            else
                high = mid - 1
            end
        end
        
        if mid == 0
            return 0
        end

        if frame >= motions[mid].flame_no
            return mid
        end
        
        return mid - 1
    end
    
    def bezie(next_motion, i, per)
        x1 = next_motion.interpolation[i * 4]
        x2 = next_motion.interpolation[i * 4 + 1]
        y1 = next_motion.interpolation[i * 4 + 2]
        y2 = next_motion.interpolation[i * 4 + 3]
        
        return bezierp(x1.to_f() / 127, x2.to_f() / 127, y1.to_f() / 127, y2.to_f() / 127, per);
    end
    
    def bezierp(x1, x2, y1, y2, x)
        t = x

        while true
            v = ipfunc(t, x1, x2) - x
            break if v * v < 0.0000001
            tt = ipfuncd(t, x1, x2)
            break if tt == 0
            t -= v / tt
        end
        
        return ipfunc(t, y1, y2)
    end
    
    def ipfunc(t, p1, p2)
        return ((1.0 + 3.0 * p1 - 3.0 * p2) * t * t * t + (3.0 * p2 - 6.0 * p1) * t * t + 3.0 * p1 * t)
    end
    
    def ipfuncd(t, p1, p2)
        return ((3.0 + 9.0 * p1 - 9.0 * p2) * t * t + (6.0 * p2 - 12.0 * p1) * t + 3.0 * p1)
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
        bone_motions()
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
        GLUT.TimerFunc(33, method(:update).to_proc(), 0)
        
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
    
    #描画領域のサイズの変更
    def reshape(w,h)
        GL.Viewport(0, 0, w, h)

        GL.MatrixMode(GL::GL_PROJECTION)
        GL.LoadIdentity()
        GLU.Perspective(45.0, w.to_f() / h.to_f(), 0.1, 100.0)
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
