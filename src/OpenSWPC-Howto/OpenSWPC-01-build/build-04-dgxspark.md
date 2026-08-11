---
title: NVIDIA DGX Spark
date: 2026-08-11
---

[NVIDIA DGX Spark](https://www.nvidia.com/ja-jp/products/workstations/dgx-spark/) はコンパクトなデスクトップマシンで，NVIDIAのARMベースのGrace CPUとBlackwell GPUを統合したGB10 Grace Blackwell Superchipを搭載したマシンです．
多くのGPU計算環境では，CPUとGPUは物理的に独立したメモリを持ちますが，DGX SparkではCPUからもGPUからも共通で使える広帯域のユニファイドメモリが128GB搭載されています（2025年発売当時のスペックです）．

世間では大規模言語モデル（LLM）をローカルで動かすことのできるマシンとして有名になりましたが，OSがLinuxベースということもあり，GPUを活用した科学技術計算向けのマシンとしても使いやすく優れたスペックを持ちます．一方，OpenSWPCを含む普通のGPUを用いた計算のコードはCPUとGPUのメモリが分かれていることを前提として書かれているため，コンパイル時のオプションに注意が必要です．また，CPUがIntelではなくARMベースであることや，その性能を引き出すためにはNVIDIAコンパイラの導入が必須であることなど，使い始めるまでの準備が少々必要です．ここでは，OpenSWPCを動かすための最小限の準備について説明します．

この記事の記載事項は，ユニファイドメモリの利用以外の部分については，Intel/AMDのCPUマシンでGPUを用いる際にも参考になるものと思います．

## 開発環境の準備

DGX SparkにはNVIDIA DGX OSが搭載されています．独自OSではありますが，[Ubuntu Linux](./build-02-ubuntu.md)がベースであり，操作方法も多くが共通です．

### 関連ツールとライブラリのインストール

まずは必要なツール群を `apt` によりインストールします．

```bash
# まずパッケージ一覧を最新の状態にする
$ sudo apt update
# GNU コンパイラ
$ sudo apt install build-essential g++ gfortran libtool
# NetCDF（Cライブラリのみ）
$ sudo apt install libnetcdf-dev
```

MPIライブラリとNetCDFのFortranライブラリはインストール不要です．前者はNVIDIAの開発環境に含まれており，後者はNVIDIAのコンパイラを用いて自力でビルドする必要があります．

### HPC SDKのインストール

NVIDIAの開発環境である[NVIDIA HPC SDK](https://developer.nvidia.com/hpc-sdk)をインストールします．公式ページの[Downloads](https://developer.nvidia.com/hpc-sdk/downloads)ページでライセンスに同意すると，各種プラットフォーム向けのインストーラの説明のリンクが表示されます．**Linux Arm Server**を選ぶと，**Bundled with CUDA version 13.2** と **Bundled with CUDA versions 13.2 and 12.9** の2種類があります．OpenSWPCのビルドには最新版だけで十分ですので，ここでは13.2のみのバージョンを選び，**Linux Arm Server Ubuntu (apt)**のリンクをクリックします．

:::{.callout-tip}
ここではARMベースのNVIDIA Grace CPUを搭載するDGX Spark用のインストーラが目的ですから，`Linux x86_64`を選んではいけないことにご注意ください．
:::

すると**Installation Instsructions**が表示されますから，そのコマンドをそのままコピーしてDGX Spark上で実行するとインストール完了です．ただし，インストールしただけではPATHが通っていません．ホームディレクトリのシェル設定ファイル（`~/.bashrc`）に以下の内容を追記し，`source ~/.bashrc` で有効化するか，再ログインします．

```bash
### NVIDIA HPC SDK
export NVARCH=Linux_aarch64
export NVCOMPILERS=/opt/nvidia/hpc_sdk
export PATH=$NVCOMPILERS/$NVARCH/26.5/compilers/bin:$PATH
export PATH=$NVCOMPILERS/$NVARCH/26.5/comm_libs/mpi/bin:$PATH
```

上記の設定に書かれているとおり，HPC SDKは`/opt/nvidia/hpc_sdk`以下にインストールされます．PATHの設定が有効になれば，以下のように`which` コマンドでFortranコンパイラ`nvfortran`とMPIコンパイラ`mpifort`が見えるはずです．

```bash
$ which nvfortran
/opt/nvidia/hpc_sdk/Linux_aarch64/26.5/compilers/bin/nvfortran
$ which mpifort
/opt/nvidia/hpc_sdk/Linux_aarch64/26.5/comm_libs/mpi/bin/mpifort
```

### NetCDF-Fortranのビルド

Fortranのモジュールを使うときに必要となるモジュール情報ファイル（`*.mod`）はコンパイラ依存のバイナリファイルのため，OpenSWPC本体をビルドするコンパイラ（nvfortran）でビルドしなければいけません．`apt install` でインストールされるものはGNU gfortranでビルドされたもののため，ここでは使いません．

ここでは，執筆当時最新版の[netcdf-fortran](https://github.com/Unidata/netcdf-fortran/) v4.6.4をビルドします．まずは適当なディレクトリでソースコードをダウンロードし，展開します．

```bash
# ダウンロード
$ wget https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.6.4.tar.gz
# 展開して移動
$ tar xvf v4.6.4.tar.gz
$ cd netcdf-fortran-4.6.4
```

インストール先は `/opt/netcdf-nv` とします．`./configure`スクリプトで`makefile`を生成します．その際，変数`FC`, `CC` に利用するNVIDIAのコンパイラ名を，また必要なコンパイルオプションも`**FLAGS`変数に設定しておきます．さらに，`--prefix`オプションでインストール先を指定します．

```bash
$ export NFDIR=/opt/netcdf-nv
$ FC=nvfortran CC=nvcc FFLAGS=-fPIC FCFLAGS=-fPIC CPPFLAGS="-I/usr/include" LDFLAGS=-L/usr/lib/aarch64-linux-gnu/ ./configure --prefix=${NFDIR}
```

あとは`make`, `sudo make install`するだけです．

```bash
# -j10 により最大10並列でコンパイルする（必須ではない）
$ make -j10
$ sudo make install
```
インストールされる `nf-config`により，コンパイル時に必要なオプションを調べることができます．

```bash
$ /opt/netcdf-nv/bin/nf-config  --all

This netCDF-Fortran 4.6.4 has been built with the following features: 

  --cc        -> nvcc
  --cflags    -> -I/opt/netcdf-nv/include -I/usr/include

  --fc        -> nvfortran
  --fflags    -> -I/opt/netcdf-nv/include -I/opt/netcdf-nv/include
  --flibs     -> -L/opt/netcdf-nv/lib -lnetcdff -L/usr/lib/aarch64-linux-gnu/ -lnetcdf -lnetcdf -lm 
  --has-f90   -> 
  --has-f03   -> yes

  --has-nc2   -> yes
  --has-nc4   -> yes

  --prefix    -> /opt/netcdf-nv
  --includedir-> /opt/netcdf-nv/include
  --version   -> netCDF-Fortran 4.6.4
```

## OpenSWPCのビルド

OpenSWPC 26.0 系[^1]にはコンパイルオプション`arch=dgx-spark`が含まれますから，それを使うだけです．参考までオプションの一覧を記載しておきます．

```makefile
# NVIDIA dgx-spark
ifeq ($(arch), dgx-spark)
  FC      = mpifort
  FFLAGS  = -fast -Minfo=all -acc -cpp -mp \
            -gpu=cc121,mem:unified
  NCLIB   = -L/opt/netcdf-nv/lib \
            -Wl,-rpath,/opt/netcdf-nv/lib
  NCINC   = -I/opt/netcdf-nv/include
  NETCDF  = -lnetcdff -lnetcdf
endif
```

NetCDFライブラリ関係の変数は，基本的には前項の`nf-config`の出力に沿って設定されています．ただし，`NCLIB`では`-Wl,-rpath,/opt/netcdf-nv/lib`とすることで，実行時に参照される動的ライブラリの場所を指定しています．これがあることで，実行時に環境変数`$LD_LIBRARY_PATH`の設定が不要になります．

もしnetcdf-fortranライブラリの導入場所が異なる場合には`NCLIB`, `NCINC`の設定を適宜変更します．

[^1]: 2026年夏公開予定

DGX Sparkはユニファイドメモリが採用されていますので，`-gpu=mem:unified`の指定が大変重要です．これがないと，同じ配列に対してCPUとGPUがそれぞれ個別にメモリを確保してしまうため，結果的に必要メモリサイズが倍になってしまいます．

なお，`FFLAGS`の`-gpu=cc121`というオプションは，**Computational Capability**と呼ばれ，NVIDIAのGPUの世代を区別するバージョン番号です．この番号は使うGPUによって異なりますが，`nvaccelinfo`コマンドで知ることができます．

```bash
$ nvaccelinfo

CUDA Driver Version:           13000
NVRM version:                  NVIDIA UNIX Open Kernel Module for aarch64  580.173.02  Release Build  (dvs-builder@U22-A24-5-4)  Tue Jun
 23 08:34:19 UTC 2026

Device Number:                 0
Device Name:                   NVIDIA GB10
Device Revision Number:        12.1

（中略）

Memory Models Flags:           -gpu=mem:separate, -gpu=mem:managed, -gpu=mem:unified
Default Target:                cc121
```

最後の2行に`cc`の値と，指定できるメモリ利用形態のオプションが記載されています．

OpenSWPCの実行時は通常どおり `mpirun -np XX ./bin/swpc_XX.x` で問題ありません．並列計算ですが，DGX Spark1台で計算する場合にMPI分割を行なう積極的なメリットはあまりありません．モデルが小さい場合には分割したほうが若干高速になるケースもあるようですが，`-np 1`が第1選択肢になると思ってよいでしょう．また，計算を始める前のモデル準備にはOpenMPも使いますから，`export OMP_NUM_THREADS=10`のように利用コア数を設定しておくとよいでしょう．