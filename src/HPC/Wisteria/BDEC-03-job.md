---
title: ジョブ投入の基本
date: 2024-08-26
date-modified: 2024-09-08
abstract: Wisteria/BDEC-01では，プログラムを実行する際に直接実行するのではなく，そのプログラムを実行するためのジョブスクリプトを作成し，それを投入する，というジョブ管理システムが用いられています．投入されたジョブは計算機が空き次第実行されます．混雑しているときは，何日も待つ必要があるでしょう．その代わり，ジョブを実行しているときには，そのCPUは自分だけが占有する，という仕組みです．ここでは，実際に簡単なジョブスクリプトを書いて投入してみましょう．
---

## システム構成

Wisteria/BDEC-01 (Odyssey) は，ひとつのCPUからなる **計算ノード** が数千個あり，その中から最大で2304ノードまで同時に使って並列計算ができます．
ひとつの計算ノード（CPU）の内部には，48個のコアがあります．したがって，単一のノード内でもコア間の並列計算ができます． OpenSWPCでは，ノード内はOpenMPによる並列計算，ノード間はMPIによる並列計算を行うのが一般的です．

1ノードあたりの最大メモリ容量は **28GB** ですので，実際には計算が必要とするメモリ容量を踏まえてノード数を選択する必要があります．たくさんのノードを使えば使うほど計算が速くなる，というわけではありません．むしろ一定以上に細かく分割すると，通信のオーバーヘッドにより計算時間はむしろ遅くなることがあります．そのような場合でも，利用したノード数✕時間で課金されますので，適切な計算資源量（ノード数）の見積もりは重要です．

## ジョブスクリプト

以下のような **ジョブスクリプト** を書いて，それを `pjsub` コマンドによって投入することでジョブを実行します．まずは非常に単純なものから試してみましょう．

## ジョブの投入

まずはワークディレクトリ `/work/${group}/${user}` 以下に適当なディレクトリ `bdec-job-example` を作成します． そのディレクトリの中で以下のようなFortranコード `hello.f90` を作成します．

::: callout-important
Wisteria/BDEC-01では，ホームディレクトリ以下ではジョブの実行ができません．これは，計算ノードからホームディレクトリ以下のファイルは見えないようになっているためです．実行ファイルや読み込みデータは，かならずワークディレクトリに置いてください．
:::

``` fortran
program test

    write(*,*) "Hello Wisteria/BDEC-01!"
    write(*,*) "start sleeping ..."
    call sleep(100)
    write(*,*) "done"

end program test
```

コンパイルコマンドは `frtpx` です．もし，`コマンドが見つかりません` と表示される場合は，`module load fj` でコンパイラをロードしてください．

``` bash
$ frtpx hello.f90 -o hello.x
```

`frtpx` はクロスコンパイラですから，ログインノードでこの実行ファイルを直接実行しようとしても，以下のようにエラーになってしまいます．

``` bash
$ ./hello.x
bash: ./hello.x: バイナリファイルを実行できません: Exec format error
```

次に，以下のようなジョブスクリプト `job.sh` を作成します．

``` bash
#!/bin/bash

#PJM -L rscgrp=short-o
#PJM -L node=1
#PJM -L elapse=00:05:00
#PJM -g ${GROUP}
#PJM -N testjob
#PJM -o testjob.out
#PJM -j

module load fj
./hello.x
```

ただし，`#PJM -g` の行は自分のアカウントの属するグループ名に変更してください．

`#PJM` から始まる行がジョブスクリプトの設定です．これは，`pjsub` コマンドによってジョブを投入する際に，そのジョブに対してどのようなリソースを割り当てるかを指定するものです．

まず，`#PJM -L rscgrp=short-o` は，リソースグループを指定しています．主に用いられるリソースグループには `short-o` と `regular-o` があります． `short-o` は最大で8時間のジョブに，`regular-o` は利用ノード（CPU）数に応じて24時間もしくは48時間までが利用可能です． `regular-o` は実際には利用ノード数に応じて `small-o` `medium-o` `large-o` `x-large-o` といったグループに自動で割り当てられます． このうち1153ノード〜2304ノードを利用する `x-large-o` だけが24時間制限で，ほかは48時間まで計算できます．

`#PJM -L node=1` は，利用するノード数を指定しています．今回は単一CPUを利用するため，1ノードを指定しています． `#PJM -L elapse=00:05:00` は，計算時間を指定しています．この例では5分です．ここで設定した時間を超えた計算は途中で打ち切られます．だからといって不必要にここの時間を長くしておくと，ジョブが実行開始されるまでの待ち時間が長くなる傾向にあります．

`#PJM -g ${GROUP}` は，計算に使うグループを指定しています．実際には `${GROUP}` には自分の所属グループ名が入ります． `#PJM -N testjob` は，ジョブ名を指定しています．ジョブ状況の問い合わせコマンドでこの名前が表示されます． `#PJM -o testjob.out` は，標準出力の保存先を指定しています． `#PJM -j` は，標準エラー出力を標準出力にマージする設定です．

::: callout-caution
-   BDECでは，`#PJM` の行のオプション指定よりあとに `#` でコメントを書くことができません．
-   `#PJM -L` オプションの変数と値の間の `=` の前後にスペースを入れないようにしてください．
:::

ジョブの投入は `pjsub` コマンドで行います．

``` bash
$ pjsub ./job.sh 
[INFO] PJM 0000 pjsub Job 4757341 submitted.
```

と `submitted.` が表示されれば投入成功です．ジョブスクリプトの指定になにか間違いがあるとこの時点でエラーがでます．

実行中の状況を確認するコマンドは `pjstat` です．

``` bash
$ pjstat
Wisteria/BDEC-01 scheduled stop time: 2024/09/27(Fri) 09:00:00 (Remain: 31days 11:40:58)

JOB_ID       JOB_NAME   STATUS  PROJECT    RSCGROUP          START_DATE        ELAPSE           TOKEN           NODE  GPU
4757341      testjob    RUNNING gv49       short-o           08/26 21:19:00<   00:00:03           0.0              1    -
```

他人のジョブ情報は基本的に見られません． 一番左に表示されているJOB_IDを用いると，投入したジョブを，以下のコマンドで削除できます．

``` bash
$ pjdel 4757341
```

ジョブの実行が終わると，以下のように未完了ジョブのないことが表示されます．

``` bash
$ pjstat
Wisteria/BDEC-01 scheduled stop time: 2024/09/27(Fri) 09:00:00 (Remain: 31days 11:38:58)

No unfinished job found.
```

Fortranプログラムで標準出力や標準エラー出力に表示したものは，ジョブスクリプトの `#PJM -o` で指定したファイルに保存されます．

``` bash
$ cat testjob.out 
 Hello Wisteria/BDEC-01!
 start sleeping ...
 done
```

## そのほかのジョブスクリプトオプション

### メール通知

ジョブスクリプトに以下の行を追加すると，ジョブの開始時，終了時，リスケジュール時にメール通知が届くようになります．

``` bash
#PJM -m b,e,r
```

メールの送信元は `PJM-admin@cc.u-tokyo.ac.jp` です．

ジョブ終了時のメールには，以下のように利用メモリ量などの統計情報が記載されます．

``` txt
Job id             : 4758981
Job name           : testjob
Job owner          : k64002
Resource group     : short-o
Job submitted from : wisteria01
Job submitted on   : /work/04/gv49/k64002/jobs/bdec-job-example
Job submitted at   : 2024/08/27 09:42:11
Job started at     : 2024/08/27 09:42:16
Job ended at       : 2024/08/27 09:43:57
Job elapase        : 00:01:41 (101)
Execution node id  : 0x0127000B
Job nodes          : 1
Used memory        : 67.4 MiB (70582272)
Job return code    : 0
signal             : -
PJM code           : 0

Job 4758981 is completed.
```

### ジョブの統計情報

ジョブスクリプトに `#PJM -s` または `#PJM -S` を追加とすると，各ノードのCPU使用率やメモリ使用量などの統計情報が保存されます．`-s` は簡易版，`-S` は詳細版です． かなり詳細な情報が得られますが，チューニングやデバッグの際以外は不要でしょう．

### ジョブ番号の取得

ョブスクリプト内では，ジョブの実行番号（Job ID）を，`${PJM_JOBID}` 変数から参照できます．結果ファイルをジョブ番号で整理するときなど，便利です．