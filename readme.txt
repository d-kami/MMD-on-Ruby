RubyでMikuMikuDanceのモデルとモーションファイルを読み込み
実行しようという物です。

実行方法
ruby main.rb

モデルを変えたい場合はダウンロードしたモデル(テクスチャ画像含む)を
modelフォルダに入れ、toonで始まるファイルはtoonフォルダに入れてください。
次に、main.rbの変数modelを変えてください。変数modelにフォルダ名を含める必要はありません。

実行に必要な物
Ruby
1.9.3で動作確認しました。
1.9以降が必要です

ruby-opengl
gemでインストールしましょう。
gem install ruby-opengl
でインストールできます。

narray
gemでインストールできます
gem install narray

ただしWindowsではDEVELOPMENT KIT
が必要になります。インストールには
http://blog.livedoor.jp/gaziya/archives/53605012.html
が参考になります。後日記あたりを参考にしましょう。

bmp.rb (このrepositoryに含まれています)
配布元
http://fear-no-context.air-nifty.com/blog/2005/08/rubybmp_13eb.html

pureimage.rb (このrepositoryに含まれています)
http://cappuccino.jp/keisuken/

MMD配布元
http://www.geocities.jp/higuchuu4/

参考にしたプログラム
http://blog.flup.jp/2009/03/12/programming_ruby_openg/
https://github.com/edvakf/MMD.js

現在の状況
モデルを読み込んで表示するのみ
(モデルによっては正常に表示できない)

http://d.hatena.ne.jp/d-kami/searchdiary?word=*[MMD]
