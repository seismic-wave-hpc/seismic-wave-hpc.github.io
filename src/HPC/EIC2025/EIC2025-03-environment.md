---
title: 解析環境の構築
date: 2024-08-26
date-modified: 2025-03-02
abstract: EICにはWINやSACなど，地震学解析に必要な伝統的なツールは揃っています．ここでは，より利便性を高めるべく，ユーザー領域にPython仮想環境を構築し，そのなかで必要なソフトウェアをセットアップする方法を紹介します．
---

ここではPythonの仮想環境基盤としてMiniforgeを導入し，その中でNumPyやPyGMTを含めた仮想環境を作成します．

::: {.callout-important}
ここで紹介する環境はいわゆる **Anaconda** として知られているPythonのパッケージ管理環境です．
研究環境でも広く使われていましたが，2024年のライセンス改訂によって，研究教育目的であっても無料で利用することが困難になりました．

ここでは，その代替としてMiniforgeを用います．MiniforgeはAnacondaのパッケージ管理コマンド `conda` と同等なものを提供する完全なオープンソースなプロジェクトです．
:::

## Miniforgeのインストール

まずは適当なディレクトリでMiniforgeを `curl` コマンドでダウンロードします．

```bash
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
```

そのディレクトリでダウンロードしたスクリプトを `bash` で実行します．

```bash
bash  ./Miniforge3-Linux-x86_64.sh -b
```

::: {.callout-important}
オプション `-b` は batch modeで，本来対話的に確認されるべきend user licence agreementやインストール先の指定などがすべて省略されます．上記コマンドを実行した時点で自動的にライセンスに同意したとみなされますので，ご注意ください．これはライセンスの確認を省略することを推奨するものではありません．
:::

すると，しばらくメッセージが流れ，最終的に

```bash
installation finished.
```

と表示されてインストールが終わります．この方法では，ホームディレクトリの直下に `miniforge3` ディレクトリが作られ，そこに関連ファイルがインストールされています．

続いて，初期化設定です．以下のようにインストールされたディレクトリにある `conda` コマンドを `init` オプションで実行します．

```bash
$ cd  # ホームディレクトリに移動
$ ./miniforge3/bin/conda init
no change     /home/j0XXXX/miniforge3/condabin/conda
no change     /home/j0XXXX/miniforge3/bin/conda
no change     /home/j0XXXX/miniforge3/bin/conda-env
no change     /home/j0XXXX/miniforge3/bin/activate
no change     /home/j0XXXX/miniforge3/bin/deactivate
no change     /home/j0XXXX/miniforge3/etc/profile.d/conda.sh
no change     /home/j0XXXX/miniforge3/etc/fish/conf.d/conda.fish
no change     /home/j0XXXX/miniforge3/shell/condabin/Conda.psm1
no change     /home/j0XXXX/miniforge3/shell/condabin/conda-hook.ps1
no change     /home/j0XXXX/miniforge3/lib/python3.12/site-packages/xontrib/conda.xsh
no change     /home/j0XXXX/miniforge3/etc/profile.d/conda.csh
modified      /home/j0XXXX/.bashrc

==> For changes to take effect, close and re-open your current shell. <==
```

ただし，`j0XXXX` はユーザー名です．表示されたとおり，初期設定ファイル `.bashrc` に `conda` コマンドの設定が書き込まれます．

```bash
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/j0XXXX/miniforge3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/j0XXXX/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/home/j0XXXX/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/home/j0XXXX/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
```

::: {.callout-important}
インストールするバージョンによっては，その下にさらにmambaの設定が書き込まれることがあります．

なお，EICでは，上記の設定をしても，ターミナルからログインしたときには自動で `conda` が有効にはなりません．VSCode経由でのSSH接続では有効化されるようです．

もし，ターミナルから `conda` を有効にしたいときには，

```bash
source ~/.bashrc
```

というコマンドで， `.bashrc` ファイルの設定を読み込ませてください．あるいは，`~/.bash_profile` というファイル（なければ作る）に上記 `source` コマンドを記述しておくと，ログイン時に直接 `conda` が使えるようになります．
:::

## Conda仮想環境の作成

Miniforgeが有効になっていると，EICのプロンプトが

```bash
(base) -bash-4.2$ 
```

のように `(base)` とついたものに変更されているはずです．
これはcondaの環境名で，初期状態 `base` が有効になっているという印です．もしそうなっていなかったら， `source ~/.bashrc` コマンドを実行して `conda` を有効化してください．

この状態では，システムに入っているPythonよりも，Miniforgeで自分がインストールしたPythonのほうが優先されます．たとえば，`python` コマンドの場所を調べてみると，

```bash
$ which python
~/miniforge3/bin/python
```

と表示され，自分のホームディレクトリ以下，Miniforgeをインストールしたディレクトリの下にpython本体が入っていること，それがシステムのpythonよりも優先されていることがわかります．

Miniforgeでは，Python本体と関連ライブラリを丸ごとまとめた **仮想環境**をいくつも作り，必要に応じて切り替えて使うことができます．ここでは，地震波の解析に必要なライブラリを入れた仮想環境 `seismo25` を作成してみます．

```bash
$ conda create --name seismo25 --channel conda-forge \
  python ipykernel pygmt gmt numpy scipy obspy netcdf4 \
  matplotlib cartopy ffmpeg
```

画面の幅の都合上複数行に分かれていますが，これで1つのコマンドです．

::: {.callout-tip}
Linuxのターミナルでは，行末にバックスラッシュ `\` を打つことで，1つのコマンドを複数行に分割できます．
:::

ここで，1行目はおもにオプション，2行目以降がインストールしたいパッケージ（ライブラリ）名です．指定したオプションの意味は以下のとおりです．

- `--name seismo25` 仮想環境の名前を `seismo25` に指定します．
- `--channel conda-forge` パッケージの検索・インストールをする提供元を指定します．`conda-forge` には非商用のパッケージがたくさん集まっており，常にここを指定しておけば間違いありません．

::: {.callout-tip}
まずパッケージなしで `conda create` により環境だけつくり，ひとつひとつのパッケージを後から追加していくこともできます．Web上の解説ではそのようなやり方が多く見られるようです．

しかし，そのやり方では**バージョンの競合**の問題が発生しやすいようです．
必要なパッケージをまとめて指定しておくことで，全パッケージが動作するよう，自動的にバージョンが調整されます．
:::

`conda create` を実行すると，指定したよりも遥かに多いパッケージが表示され（依存関係の問題です）

```bash
Proceed ([y]/n)? 
```

と訊かれますので，`y` を入力します．すると，しばらく端末上にインストールの経過が表示されます．インストールには多少の時間がかかります．数分待つと，

```bash
Preparing transaction: done
Verifying transaction: done
Executing transaction: done
#
# To activate this environment, use
#
#     $ conda activate seismo25
#
# To deactivate an active environment, use 
# 
#     $ conda deactivate
```

と表示され，インストール完了です．このメッセージの通り，condaが有効になった状態で，

```bash
(base) -bash-4.2$ conda activate seismo25 # seismo24環境を有効化
(seismo25) -bash-4.2$ conda deactivate    # seismo24環境を無効化
(base) -bash-4.2$ conda deactivate        # conda自体を無効化
-bash-4.2$
```

というように，`conda activate` と `conda deactivate` で有効，無効を切り替えられます．
さらに `base` 環境で `conda deactivate` すると，`conda` 自体を無効化できます．

ともあれ，これで一通りのツールが使えるようになりました．

PyGMTやObsPyの初回インポートには多少の時間がかかりますが，初期化にともなうもののようです．
VSCodeで接続した場合は，EICリモート環境にPython+Jupyterの拡張機能をインストールすれば，ipynbファイルの編集経由でインストールしたKernelを指定して利用できます．

![](./fig/EIC-PyGMT.png)

上図は，VSCodeでEICに接続し，そこで上述の環境でJupyter Notebookを利用し，PyGMTにより地図を描画したものです．このような環境を整備しておくと，EIC上実施した数値シミュレーションの可視化や事後解析をEIC上でそのまま実施できて，便利になることでしょう．
