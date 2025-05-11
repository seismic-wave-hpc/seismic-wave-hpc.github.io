## Ubuntu Linux + gfortran

[Ubuntu Linux](https://ubuntu.com) は，[Debian GNU/Linux](https://www.debian.org)から派生したLinuxディストリビューションです．使いやすさが重視されたディストリビューションで，Linuxの数多くのディストリビューションのなかでも特に利用者の多いディストリビューションのようです．Microsoft WindowsでLinuxを動作させるWindows Subsystem for Linux 2 (WSL2) のデフォルトディストリビューションでもあります．

Ubuntu LinuxはDebianの派生であり，またUbuntuからさらに派生したディストリビューションも[多数](https://w.atwiki.jp/linuxjapanwiki/pages/55.html)あります．有名で利用者が多いものに，Debianのほか[Linux Mint](https://linuxmint.com)が挙げられます．それら関連ディストリビューションでは，同じ `apt` コマンドによるパッケージ管理システムが導入されている場合が多く，以下のビルド方法がそのまま使える必要があります．

### Ubuntuにおけるビルド

`apt` コマンドによる関連パッケージのインストールには管理者権限が必要です．Ubuntu Linuxでは `sudo` コマンドにより管理者としてコマンドを実行します．

```bash
# まずパッケージ一覧を最新の状態にする
$ sudo apt update
# 関連ライブラリ 
$ sudo apt install gfortran
$ sudo apt install openmpi-bin libopenmpi-dev
$ sudo apt install netcdf-bin libnetcdf-dev libnetcdff-dev
```

Ubuntuにおいては，MPIライブラリであるOpenMPIやNetCDFが，実行ファイルのパッケージ（`**-bin`）とコンパイル時にリンクするライブラリ群（`lib**-dev`）に分かれています．原則として両方のインストールをお勧めします．

::: {.callout-note}
実は`netcdf-bin` はNetCDFファイルに関する実行プログラムで，OpenSWPCのビルドそのものには不要です．ですが，OpenSWPCの入出力ファイルであるnetcdfファイルの内容を確認できる `ncdump` コマンドが含まれるため，これもあわせてインストールしておくことをお勧めします．
:::

```bash
# curlコマンドでダウンロードし，unzipで展開．
# もちろんブラウザからダウンロードしてダブルクリックして展開しても構わない
$ curl -OL https://github.com/OpenSWPC/OpenSWPC/archive/refs/tags/25.01.zip
$ unzip 25.01.zip
# ソースコードディレクトリに移動してビルド
$ cd OpenSWPC-25.01/src
$ make arch=ubuntu-gfortran
```

これですべてのシミュレーションコードと関連ツールに関するビルドが走り，しばらくすると `./bin/` ディレクトリ以下に実行ファイルが生成されます．

## Ubuntu Linux + intel compiler

To be available soon!
