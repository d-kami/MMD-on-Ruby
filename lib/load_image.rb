require './lib/image/bmp.rb'
require './lib/image/pureimage.rb'

module LoadImage
    #toonファイルの名前を配列にセットする
    def create_toons(model)
        toons = Array.new()
        
        #toon_indexが-1のときのtoonファイル
        toons[10] = 'toon00.bmp'
    
        if model.toon_texture == nil
            #toonファイルの名前に指定が無い場合はデフォルトのファイル名を使う
            10.times do |index|
                toons[index] = get_default_toon(index)
            end
        else
            10.times do |index|
                if model.toon_texture.names[index] != nil && model.toon_texture.names[index].end_with?('.bmp')
                    #toonファイルの名前に指定がある
                    toons[index] = model.toon_texture.names[index]
                else
                    #toonファイルの名前に指定が無いのでデフォルトのファイル名を使う
                    toons[index] = get_default_toon(index)
                end
            end
        end
        
        return toons
    end

    #toonファイルを読み込み、テクスチャとして設定する
    def load_toons(toons, textures)
        toons.length.times do |index|
            bitmap = BitMap.read("./toon/#{toons[index]}")
            image = get_raw(bitmap)

            textures[toons[index]] = create_texture(image, bitmap.width, bitmap.height)
        end
    end

    #スフィアマップ用のテクスチャを読み込み設定する
    def load_sphere(material, textures)
        if material.sphere != nil && !textures.key?(material.sphere)
            textures[material.sphere] = load_bmp("./model/#{material.sphere}")
        end
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

    #マテリアルに設定されているテクスチャを読み込む
    def load_texture(material, textures)
        if material.texture != nil && !textures.key?(material.texture)
            #読み込むテクスチャが存在していて、まだ登録されてない場合の処理
            
            if material.texture.end_with?('.bmp')
                #bmpファイルをテクスチャとする
                textures[material.texture] = load_bmp("./model/#{material.texture}")
            elsif material.texture.end_with?('.png')
                pngio = PureImage::PNGIO.new()
                png = pngio.load("./model/#{material.texture}")
                image = get_raw_png(png)
                #pngファイルをテクスチャとする
                textures[material.texture] = create_texture(image, png.width, png.height)
            end
        end
    end

    
    #bmpを読み込み、テクスチャにして返す
    def load_bmp(file_name)
        bitmap = BitMap.read(file_name)
        image = get_raw(bitmap)
        return create_texture(image, bitmap.width, bitmap.height)
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
    
    #index番目のデフォルトのファイル名を返す
    def get_default_toon(index)
        if index == 9
            return "toon#{index + 1}.bmp"
        else
            return "toon0#{index + 1}.bmp"
        end
    end
end
