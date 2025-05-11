## macOS (Apple Silicon)

[macOS](https://www.apple.com/jp/macos) はAppleのMac製品のためのオペレーティングシステムです．BSD系とよばれる一種のUnixをベースに開発されており，Mac OS X 10.5 (Leopard) からは公式にUNIXの一種として認証されています．そのため，Terminal.app を通じてUnixコマンドを動作させることができます．

それに加えて，パッケージ管理システム [Homebrew](https://brew.sh/ja/) を用いてOpenSWPCに必要なソフトウェア一式を簡単に導入することができます．そのため，配布パッケージに Homebrewの利用を前提とした macOS でのビルドオプションが用意されています．

::: {.callout-note}
macOSのパッケージ管理ツールには，ほかに [Fink](https://www.finkproject.org/index.php?phpLang=ja) や [MacPorts](https://www.macports.org) などがあります．いずれもHomebrewが流行するより前にメジャーだったパッケージツールで，現在も開発やメンテナンスが続いているようです．ただし，macOSにおけるOpenSWPCのビルドはあくまでもHomebrewの利用を前提としています．
:::

### macOSにおけるビルド

```bash
# Homebrewのインストール（途中で管理者パスワードを要求される）
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# brewの動作確認
$ brew doctor
```

```bash
brew install gcc             # gfortranがこの中に含まれる
brew install open-mpi        # MPIのライブラリと実行環境
brew install netcdf          # NetCDFライブラリ本体
brew install netcdf-fortran  # FortranからNetCDFを利用するためにこちらも必要
```

ここまでで，`/opt/homebrew/bin` に `gfortran` や `mpif90` などの実行ファイルが，`/opt/homebrew/lib` にライブラリ，`/opt/homebrew/include` にインクルードファイル（この場合は `netcdf.mod` というFortranからNetCDFを利用するためのモジュール情報ファイル）がインストールされているはずです．また，Homebrewが正常にインストールされていれば，`/opt/homebrew/bin` には PATHが通っており，その下のファイルはコマンド名だけでどこからでも実行できるはずです．

```bash
# curlコマンドでダウンロードし，unzipで展開．
# もちろんブラウザからダウンロードしてダブルクリックして展開しても構わない
$ curl -OL https://github.com/OpenSWPC/OpenSWPC/archive/refs/tags/25.01.zip
$ unzip 25.01.zip
# ソースコードディレクトリに移動してビルド
$ cd OpenSWPC-25.01/src
$ make arch=mac-gfortran
```

これですべてのシミュレーションコードと関連ツールに関するビルドが走り，しばらくすると `./bin/` ディレクトリ以下に実行ファイルが生成されます．
