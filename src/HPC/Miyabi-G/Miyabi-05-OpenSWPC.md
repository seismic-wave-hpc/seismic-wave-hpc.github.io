---
title: OpenSWPCの利用
date: 2026-08-13
abstract: Miyabi-GにおけるOpenSWPCの利用法について説明します．
---


## OpenSWPCのダウンロードとコンパイル

OpenSWPCは <https://github.com/OpenSWPC/OpenSWPC> で公開されています．
このURLから見られる個別のソースコードは，開発の途中で登録されている場合があり，したがって未完成だったりバグを含むこともあります．
それに対して，一定のアップデートのまとまりごとに **release** としてバージョン番号を付与されたものがzip形式で圧縮されて [https://github.com/OpenSWPC/OpenSWPC/releases](https://github.com/OpenSWPC/OpenSWPC/releases) から公開されています．
このreleaseはZenodoによりバージョン個別のDOIが付与（たとえば [こちら](https://doi.org/10.5281/zenodo.16264099)）されており，論文等での引用にも便利です．

ここでは，Version 25.05.2をダウンロード・コンパイルしてみます．

```bash
$ curl -OL https://github.com/OpenSWPC/OpenSWPC/archive/refs/tags/25.05.2.zip
$ unzip 25.05.2.zip
$ cd OpenSWPC-25.05.2/src
$ make arch=miyabi-G
```

でコンパイルできます．

Miyabi-Gでは，ライブラリや開発環境などを`module load`コマンドで読み込んで使う仕組みが採用されています．OpenSWPCのコンパイル時に`module load` は自動的に行われますが，`make` 前にロードされていたモジュールはpurgeされてしまうので注意してください．

なお，`read_snp.x`などの付属ツールをログインノードやインタラクティブノードで利用するためには，実行前に

```bash
$ module load nvidia netcdf netcdf-fortran hdf5
```

によって必要なライブラリを読み込む必要があります．一度読み込めばそのシェルではずっと有効です．Miyabi-GではNVIDIAによるコンパイラのみを使う，というつもりであれば，上記`module load`コマンドをシェル設定ファイル`~/.bashrc`に書いておけば，次回ログイン時からはこれらのモジュールが自動で読み込まれます．

## データセットの準備

日本周辺のモデルとしてJIVSMを使いたい場合は，公式マニュアルの[記述](https://openswpc.github.io/ja/1._SetUp/0104_dataset/)に沿ってデータの準備が必要です．このデータは使い回せるため，共通のディレクトリに保存しておくのが良いでしょう．

## ジョブ投入の例

OpenSWPCのジョブスクリプトの例です．これはOpenSWPCに同梱されている西南日本のサンプルジョブの例です．ただし，入力パラメタに若干の修正が必要です．これについては後述します．

```bash
#!/bin/bash

#PBS -q regular-g
#PBS -l select=48:mpiprocs=1:ompthreads=36
#PBS -l walltime=01:00:00
#PBS -W group_list=GROUP
#PBS -j oe
#PBS -N SWPC_W
#PBS -m abe
#PBS -l mail_power_info=true

cd ${PBS_O_WORKDIR}
module load nvidia nv-hpcx netcdf hdf5 netcdf-fortran
mpirun ./bin/swpc_3d.x -i ./example/input_WJapan.inf
```

基本的なジョブスクリプトの書き方は[前節](./Miyabi-04-job.md)で説明したとおりです．ここでは主な違いについて説明します．

### MPI/OpenMPハイブリッドジョブ設定

```bash
#PBS -l select=48:mpiprocs=1:ompthreads=36
```

では，単に48ノードを確保するだけでなく，**ノードあたりのMPIプロセス数**を`mpiprocs`オプションで，**1プロセスあたりのOpenMPスレッド数**を`ompthreads`オプションで指定します．

OpenSWPCでは1ノード（1GPU）あたり1プロセスで実行することが想定されています．より細かく1ノードを複数に分割することもでき，場合によって若干の性能の変化が見られますが，実用上はあまり気にする必要はないと思われます．`mpiprocs=1`を常に使い，入力パラメタの`nproc_x`と`nproc_y`の積が`select=`の数値と一致するように選べばよいです．

次の`ompthreads`のオプションを指定すると，OpenMPによる並列計算が有効となります．OpenSWPCは，Miyabi-GのようなGPUマシンにおいて，（Version25系の時点においては）主要な演算のほぼ全てをGPUで行います．一方，計算の開始前の構造や震源モデルデータの読み込みと差分グリッドへの割り当ては（GPUからはストレージのファイルを直接読めないので必然的に）CPUで行っており，そこではCPU内の複数コアを用いたOpenMP並列化が実装されています．そのため，`ompthreads`をCPUのコア数以下の範囲で指定することで高速化が期待できます．

### モジュールの読み込み

Miyabi-GのOpenSWPCはNVIDIA [HPC-X](https://developer.nvidia.com/networking/hpc-x)の環境でコンパイルされているため，そのライブラリと入出力につかうNetCDF関係のライブラリ，さらにそれが依存しているHDFライブラリを読み込む必要があります．`swpc_**.x`を実行するときには必ず

```bash
module load nvidia nv-hpcx netcdf hdf5 netcdf-fortran
```

が必要です．

## 環境変数利用についての注意

OpenSWPCの入力パラメタファイルでは`export`で指定した**環境変数**が読み込めるようになっています．配布ファイルに同梱されている入力パラメタファイルでも，たとえば

```Fortran
dir_grd  = '${DATASET}/vmodel/ejivsm/'  !! directory for grd file
```
が指定されており，あらかじめ
```bash
export DATASET=/path/to/dataset
```
という環境変数が設定されていれば，OpenSWPC内部では
```Fortran
dir_grd = '/path/to/dataset/vmodel/ejivsm/'
```
に展開されます．これは特に上記データセットをいつでも共通のディレクトリにしておくのに便利な仕組みです．

ところが，Miyabiの並列実行ジョブでは，ジョブ実行ファイル内で `export`文により環境変数を設定しても，**すべての計算ノードのうち1ノードにしか環境変数が伝わらない**という問題があります．マニュアルによるとこれは仕様のようです．

`mpirun`のオプションを用いて，先のジョブスクリプトを以下のようにすることで環境変数を渡すこともできます．
```bash
#!/bin/bash

#PBS -q regular-g
#PBS -l select=48:mpiprocs=1:ompthreads=36
#PBS -l walltime=01:00:00
#PBS -W group_list=GROUP
#PBS -j oe
#PBS -N SWPC_W
#PBS -m abe
#PBS -l mail_power_info=true

unset OMPI_MCA_mca_base_env_list
export DATASET=/path/to/dataset

cd ${PBS_O_WORKDIR}
module load nvidia nv-hpcx netcdf hdf5 netcdf-fortran
mpirun -x PATH -x LD_LIBRARY_PATH -x DATASET \
       ./bin/swpc_3d.x -i ./example/input.inf
```
しかしこの方法だと`${PATH}`と`${LD_LIBRARY_PATH}`も手動で渡す必要があり，やや煩雑です．Miyabi-Gにおいてはパラメタに環境変数を使わない，ほうが簡単かもしれません．