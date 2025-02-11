---
title: OpenSWPCの利用
date: 2024-08-26
date-modified: 2024-09-08
abstract: OpenSWPCはVersion 5.2.0 以降でWisteria/BDECにおけるコンパイルに対応しています．ここではそのコンパイル方法とジョブの投入方法を説明します．
---

## OpenSWPCのダウンロードとコンパイル

OpenSWPCは https://github.com/OpenSWPC/OpenSWPC で公開されています．
このURLから見られる個別のソースコードは，開発の途中で登録されている場合があり，したがって未完成だったりバグを含むこともあります．
それに対して，一定のアップデートのまとまりごとに **release** としてバージョン番号を付与されたものがzip形式で圧縮されて [https://github.com/OpenSWPC/OpenSWPC/releases](https://github.com/OpenSWPC/OpenSWPC/releases) から公開されています．
このreleaseはZenodoによりバージョン個別のDOIが付与（たとえば [こちら](https://doi.org/10.5281/zenodo.13756043)）されており，論文等での引用にも便利です．

ここでは，公開されている最新版Version 24.09.1をダウンロード・コンパイルしてみます．

```bash
$ curl -OL https://github.com/OpenSWPC/OpenSWPC/archive/refs/tags/24.09.1.zip
$ unzip 24.09.1.zip
$ cd OpenSWPC-24.09.1/src
$ make arch=bdec-o
```

とするだけでコンパイルできます．
コンパイル時に，`module load` は自動的に行われますが，`make` 前にロードされていたモジュールはpurgeされてしまうので注意してください．

グループ `gv49` については，`/work/gv49/share/dataset` に構造や観測点位置モデルが配置済みです．あるいは，あらかじめ [構造モデルを作成](https://openswpc.github.io/ja/1._SetUp/0104_dataset/) して適当なディレクトリに転送しておいてください．

`swpc_**` は計算ノードで，`tools/*` はログインノードで実行できるようにコンパイルされますが，`read_snp.x` などのツールを動かすためには
```bash
$ module load intel netcdf netcdf-fortran hdf5
```
の実行が必要です．

## ジョブ投入の例

それでは，ジョブスクリプトを書いて投入してみましょう．

```bash
#!/bin/bash

#PJM -L    rscgrp=regular-o
#PJM -L    node=4x4:mesh     
#PJM --mpi proc=16
#PJM -L    elapse=00:30:00
#PJM -g    ${GROUP}  #<-- 自分の所属グループに変更
#PJM --omp thread=48
#PJM -N    bdec-001         
#PJM -o    bdec-001.out
#PJM -j 
# ---------- 

# 計算に必要なモジュールのロード．OpenSWPCはNetCDFを利用するため，それと関連のモジュールをロードしている
module load fj fjmpi netcdf hdf5 netcdf-fortran

# プログラムの実行．mpiコードの実行コマンドは mpiexec
mpiexec ./bin/swpc_3d.x -i in/input.inf
```

ジョブスクリプトの書き方は基本的に [前述](./BDEC-03-job.md) のとおりですが，いくつかの違いがあります．

まず，`#PJM -L node=4x4:mesh` は，ノードサイズを指定しています．`4x4:mesh` は，4x4の2次元メッシュを指定しています．単にノード数を指定するだけでなく，このようにノード間の接続の形状の指定もできます．OpenSWPCは媒質をXY方向の2次元に分割するため，その分割とmesh形状を対応させると速度がやや向上します．ただし，複雑なメッシュ形状を指定すると，その分ジョブが実行開始されるまでの待ち時間が長くなることもあります．

`#PJM --mpi proc=16` は，MPIのプロセス数を指定しています．ノード内をOpenMPで，ノード間この例では16プロセスを指定しています． `#PJM --omp thread=48` は，OpenMPのスレッド数を指定しています．この例ではCPUのすべてのスレッド（48スレッド）をまとめて使います．

プログラムの実行前に，そのプログラムが利用するライブラリを `module` コマンドでロードする必要があります．この例の場合，OpenSWPCがNetCDFを用いるため，それ（`netcdf`, `netcdf-fortran`）と依存ライブラリであるHDF5（`hdf5`）をロードしています．

このジョブスクリプト `job.sh` を以下のコマンドで投入することで，計算が開始されます．

```bash
$ pjsub job.sh
```

## 既知の問題

### read_snp.x
大きなスナップショット（1辺2000グリッド以上）で実行時エラーが起きる（他のLinux環境では起きない）．回避方法検討中．

### まれに計算が終わってもなかなか終了しないことがある
現象観察中．
