---
title: OpenSWPCの利用
date: 2026-08-13
abstract: EIC計算機システムにおけるOpenSWPCの利用法について説明します．
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
$ make arch=eic2025
```

でコンパイルできます．

EIC計算機システムでは，ライブラリや開発環境などを`module load`コマンドで読み込んで使う仕組みが採用されています．OpenSWPCのコンパイル時に`module load` は自動的に行われますが，`make` 前にロードされていたモジュールはpurgeされてしまうので注意してください．

## データセットの準備

日本周辺のモデルとしてJIVSMを使いたい場合は，公式マニュアルの[記述](https://openswpc.github.io/ja/1._SetUp/0104_dataset/)に沿ってデータの準備が必要です．このデータは使い回せるため，共通のディレクトリに保存しておくのが良いでしょう．

## ジョブ投入の例

OpenSWPCのジョブスクリプトの例です．

```bash
#!/bin/bash
#PBS -q E
#PBS -l select=1:ncpus=192:mpiprocs=96:ompthreads=2
#PBS -N FDMWS06
#PBS -j oe

module load PrgEnv-intel
module load cray-pals
module load cray-pmi
module load HDF5/1.14.5/intel/2024.2.1 NetCDF/4.9.2/intel/2024.2.1

cd $PBS_O_WORKDIR

export DATASET=/home/j01246/share/dataset/
mpirun -d ${OMP_NUM_THREADS} ./bin/swpc_3d.x -i input.inf

```
計算規模と並列化のパラメタとしては

```Fortran
nproc_x = 12       !! parallelization in x-dir
nproc_y = 8        !! parallelization in y-dir
nx      = 2400     !! total grid number in x-dir
ny      = 2400     !! total grid number in y-dir
nz      = 1000     !! total grid number in z-dir
nt      = 16000    !! time step number
```
のものです．グリッドサイズとしてはこのくらいがEIC計算機システム（2025年度版）で動かせる上限です．これで17時間ほどの計算時間がかかります．また，同時に実行できるジョブ数が少ないため，混雑状況によっては実行開始まで数日待つことになるかもしれません．大規模な計算が必要であれば別途[Miyabi](../Miyabi-G/Miyabi-00-index.md)の利用を勧めます．


基本的なジョブスクリプトの書き方は[前節](./EIC2025-04-job.md)で説明したとおりです．ここでは主な違いについて説明します．

### MPI/OpenMPハイブリッドジョブ設定

```bash
#PBS -l select=1:ncpus=192:mpiprocs=96:ompthreads=2
```

では，ジョブクラス`E`において192コアを使い，そこでMPIを96プロセス立ち上げます．さらに，1プロセスあたり2コアのOpenMP並列を使うハイブリッド並列計算にしています．後半の`ompthreads=2`がOpenMPの指定です．

多くのスーパーコンピュータでは1CPUあたり1プロセスを使いますが，テスト計算の結果EIC計算機システムにおいては例外的に2CPUのなかで多数のプロセスを立ち上げたほうが計算効率が高いことがわかっています．

### モジュールの読み込み

OpenSWPCはNetCDFを使いますので，

```bash
module load HDF5/1.14.5/intel/2024.2.1 NetCDF/4.9.2/intel/2024.2.1
```

が必要です．

## 環境変数の利用

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
