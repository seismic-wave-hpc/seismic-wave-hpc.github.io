---
title: 解析環境の構築
date: 2025-05-11
date-modified: 2025-05-13
draft: true
abstract: "Miyabi-Gのログインノードで研究開発をするための環境を整備します．"
---

以下では， `${user}` が個人ユーザーIDを，`${group}` がグループ名を表すものとします．コマンドを実行する際には読み替え（書き換え）て実行してください．なお，複数のグループに所属している場合は，主に使うひとつを選択してください．

## シンボリックリンクの作成

ログイン先のホームディレクトリに，ワークディレクトリをリンクしておくと何かと便利です．`ln -s` コマンドにより実現できます．

```bash
ln -s /work/${group}/${user} ~/work
```

上記コマンドで，ホームディレクトリの直下に `work` という名前のリンクが生成されます．

## ファイル数制限への対処

Miyabiでは，ホームディレクトリに1ユーザーが作成できるファイルの数が102,400と**きわめて少なく**設定されています．自分で直接作成するファイル数よりは多く見えるかもしれませんが，VSCodeでSSH接続した際に作成される `.vscode-server` ディレクトリの下のファイルは容易に数万を超えることがあります．そこで，以下のように

もしすでにVSCodeでSSH接続していた場合，`~/.vscode-server` というディレクトリがあるはずです．ターミナルから

```bash
mv ~/.vscode-server ~/work
ln -s ~/work/.vscode-server .
```

と移動し，かつそのディレクトリをホームディレクトリにリンクします．前節で作成した `work` シンボリックリンクを早速活用しました．

あるいはもしこれまでVSCode以外の端末からの接続をしていて，ホームディレクトリで `ls -a` をしても（`-a` は `.`で始まる名前の隠しファイルも表示するオプション） `.vscode-server` ディレクトリが見当たらない場合は，以下のように空ディレクトリを作成して，それにリンクをかけておけばよいでしょう．

```bash
mkdir ~/work/.vscode-server
ln -s ~/work/.vscode-server .
```

こうしておけば，`~/.vscode-server`以下に大量のファイルが作られても，その実体はワークディレクトリにありますから，ファイル数制限の影響を受けることはありません．

## Miniforgeのインストール

ここではPythonの仮想環境基盤としてMiniforgeを導入し，その中でNumPyやPyGMTを含めた仮想環境を作成します．

::: {.callout-important}
ここで紹介する環境はいわゆる Anaconda として知られているPythonのパッケージ管理環境です． Anacondaは研究目的にも広く使われていたのですが，2024年のライセンス改訂によって，研究教育目的であっても無料で利用することが困難になりました．

ここでは，その代替としてMiniforgeを用います．MiniforgeはAnacondaのパッケージ管理コマンド conda と同等なものを提供する完全なオープンソースなプロジェクトです．
:::

まず，適当なディレクトリをつくり，その中でインストーラをダウンロードします．

```bash
mkdir setup
cd setup
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
```

すると，(Miyabi-G環境なら) `Miniforge3-Linux-aarch64.sh` が生成されているはずです．これをバッチモード (`-b`) で実行してMiniforgeをインストールします．

::: {.callout-important}
オプション `-b` は batch modeで，本来対話的に確認されるべきend user licence agreementやインストール先の指定などがすべて省略されます．上記コマンドを実行した時点で自動的にライセンスに同意したとみなされますので，ご注意ください．これはライセンス確認の省略を推奨するものではありません．
:::

::: {.callout-warning}
これから作成する conda 環境も，数万を超える大量のファイルを生成します．インストーラが仮定するデフォルトのインストール先はホームディレクトリ直下の `miniforge3` ディレクトリなのですが，前節と同じ理由により，ワーク領域にインストールすることを強く推奨します．
:::

```bash
bash ./Miniforge3-Linux-aarch64.sh -b -p ~/work/miniforge3
```

ここで `-p ~/work/miniforge3` オプション（PREFIX）でインストール先を変更しています．
しばらくメッセージが流れ，インストールがなされます．

続けて，初期化設定です．以下のようにインストールされたディレクトリにある `conda` コマンドを `init` オプションで実行します．

```bash
~/work/miniforge3/bin/conda init
no change     /work/${group}/${user}/miniforge3/condabin/conda
no change     /work/${group}/${user}/miniforge3/bin/conda
no change     /work/${group}/${user}/miniforge3/bin/conda-env
no change     /work/${group}/${user}/miniforge3/bin/activate
no change     /work/${group}/${user}/miniforge3/bin/deactivate
no change     /work/${group}/${user}/miniforge3/etc/profile.d/conda.sh
no change     /work/${group}/${user}/miniforge3/etc/fish/conf.d/conda.fish
no change     /work/${group}/${user}/miniforge3/shell/condabin/Conda.psm1
no change     /work/${group}/${user}/miniforge3/shell/condabin/conda-hook.ps1
no change     /work/${group}/${user}/miniforge3/lib/python3.12/site-packages/xontrib/conda.xsh
no change     /work/${group}/${user}/miniforge3/etc/profile.d/conda.csh
modified      /home/${user}$/.bashrc

==> For changes to take effect, close and re-open your current shell. <==
```

画面に表示されたとおり，ホームディレクトリの `bash` 設定ファイル `.bashrc` に `conda` の設定が追記されています．
具体的には

```bash
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/work/${group}/${user}/miniforge3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/work/${group}/${user}/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/work/${group}/${user}/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/work/${group}/${user}/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
```

という記述が追加されているはずです．ここまでくれば，インストーラファイルは削除してしまって差し支えありません．

### Miyabi-C&G 共存設定

ログインノードとしてMiyabi-Gだけを使うならばこのままでも問題ないのですが，このままではMiyabi-Cで正常にログインできなくなってしまっています．
`.bashrc`にかかれている内容はログイン時に読み込まれるのですが，その中の `conda` の設定で実行されるプログラムが，Miyabi-Gの `aarch64` アーキテクチャでしか動作しないためです．そこで，上記の `.bashrc` の設定の前後に `if` 文を追加して，以下のようにします．

```bash
if [[ "${HOSTNAME}" == *"miyabi-g"* ]]; then
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/work/${group}/${user}/miniforge3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/work/${group}/${user}/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/work/${group}/${user}/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/work/${group}/${user}/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
fi
```

これで `conda` の設定は Miyabi-G のログインノードにログインしたときだけ実行されるようになりました．

::: {.callout-tip}
この方法を応用すれば，Miyabi-C でも別のディレクトリにminiforgeを別途インストールして，ログインノードによって実行されるcondaを切り分けることもできます．
:::

### Conda仮想環境の作成

Miniforgeが有効になっていると，Wisteria/BDECのプロンプトが

```bash
(base) [USERNAME@miyabi-g1 ~]$
```

のように `(base)` とついたものに変更されているはずです． これは`conda`の環境名で，初期状態 `base` が有効になっているという印です．

この状態では，システムに入っているPythonよりも，Miniforgeで自分がインストールしたPythonのほうが優先されます．たとえば，python コマンドの場所を調べてみると，

```bash
which python
/work/${group}/${user}/miniforge3/bin/python
```

と表示され，自分のホームディレクトリ以下，Miniforgeをインストールしたディレクトリの下に `python` 本体が入っていること，それがシステムの`python` よりも優先されていることがわかります．

Miniforgeでは，`python`本体と関連ライブラリを丸ごとまとめた 仮想環境をいくつも作り，必要に応じて切り替えて使うことができます．ここでは，地震波の解析に必要なライブラリを入れた仮想環境 seismo25 を作成してみます．

```bash
conda create --name seismo25 --channel conda-forge \
python ipykernel pygmt gmt numpy scipy obspy netcdf4 \
matplotlib cartopy ffmpeg
```

画面の幅の都合上2行に分かれていますが，これで1つのコマンドです．ここで，1行目はおもにオプション，2行目がインストールしたいパッケージ（ライブラリ）名です．指定したオプションの意味は以下のとおりです．

- `--name seismo25` 仮想環境の名前を seismo24 に指定します．
- `--channel conda-forge` パッケージの検索・インストールをする提供元を指定します．`conda-forge` には非商用のパッケージがたくさん集まっており，常にここを指定しておけば間違いありません．

::: {.callout-tip}
まずパッケージなしで conda create により環境だけつくり，ひとつひとつのパッケージを後から追加していくこともできます． Web上の解説ではそのようなやり方が多く見られるようです．

しかし，そのやり方ではバージョンの競合が発生しやすいようです． 必要なパッケージをまとめて指定すると，すべてのパッケージが動作するよう自動的にバージョンが調整されますので，おすすめです．
:::

`conda create` を実行すると，指定したよりも遥かに多いパッケージが表示され（依存関係の問題です）

``` bash
Proceed ([y]/n)? 
```

と訊かれますので，`y` を入力します．すると，しばらく端末上にインストールの経過が表示されます．インストールには多少の時間がかかります．数分待つと，

``` bash
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

``` bash
(base) -bash-4.2$ conda activate seismo25 # seismo24環境を有効化
(seismo25) -bash-4.2$ conda deactivate    # seismo24環境を無効化
(base) -bash-4.2$ conda deactivate        # conda自体を無効化
-bash-4.2$
```

というように，`conda activate` と `conda deactivate` で有効，無効を切り替えられます． さらに `base` 環境で `conda deactivate` すると，`conda` 自体を無効化できます．

ともあれ，これで一通りのツールが使えるようになりました．

PyGMTやObsPyの初回インポートには多少の時間がかかりますが，初期化にともなうもののようです． VSCodeで接続した場合は，リモート環境にPython+Jupyterの拡張機能をインストールすれば，ipynbファイルの編集経由でインストールしたKernelを指定して利用できます．

:::{.callout-note}
ログイン元のマシンだけではなくリモート接続したおいてもPythonとJupyter拡張機能をインストールする必要があることにご注意ください．
:::
