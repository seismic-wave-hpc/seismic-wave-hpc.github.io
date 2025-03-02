---
title: 補遺：EIC接続の踏み台設定
date: 2024-08-26
date-modified: 2025-03-02
abstract: "EICでは接続元が `ac.jp` か `go.jp` で，かつDNSの逆引きに対応していないと接続ができません．そのような場合に，EICに接続できる別のサーバを踏み台にして接続する方法を紹介します．ここでは東京大学情報基盤センターのスパコン（Wisteria/BDEC）を踏み台にすることを前提に説明しますが，接続元の組織内の特定のIPアドレスのマシンからのみ接続ができるような場合にもほとんど同じ設定方法が利用できます．
"
---

## 手動による二段階接続

まずはWisteria/BDECに接続します．

```bash
$ ssh -Y wisteria.cc.u-tokyo.ac.jp -l USERNAME-of-BDEC
```
さらにそこから 
```bash
$ ssh -Y eic.eri.u-tokyo.ac.jp -l USERNAME-of-EIC
```
とすれば，EICに接続できます．

しかし，毎回二段階でログインするのはとても面倒です．
`rsync` などを使ってファイルを転送する際にも，いちいち踏み台サーバにファイルを置いてからEICに転送することとなり，非効率です．

## SSH configによる自動二段階接続

ここでは，踏み台サーバ（この場合はWisteria/BDEC）への接続が公開鍵認証方式であることと，その公開鍵はEICへの接続の公開鍵と同一のものを使っていることを仮定します．

SSHでは， `~/.ssh/config` というファイルを作成し，その中に接続情報を記述することで，`ssh` コマンドが接続時にその情報を参照できます．
まずは，Wisteria/BDECへの接続を単純化してみましょう．

接続元マシンで，`config` ファイルを開きます（なければ作成します）．

```bash
$ cd ~/.ssh
$ code config
```

::: {.callout-note}
ここではVSCodeのシェルコマンド `code` がインストールされている前提で例を書いていますが，使うエディタは何でも構いません．ただし，`.ssh` はドット記号から始まる隠しディレクトリですので，エクスプローラ（Windows）やFinder (macOS) からは見えません．ターミナルで `ls -a` すると見えるはずです．
:::

`config` ファイルに以下の内容を記述します．ただし，`USERNAME-of-BDEC` は自身のWisteria/BDECユーザー名です．
`IdentifyFile` の行では接続に用いる秘密鍵を指定します．

```bash
Host bdec
     HostName wisteria.cc.u-tokyo.ac.jp
     User USERNAME-of-BDEC
     IdentityFile ~/.ssh/id_rsa
     ForwardX11 yes
```

この準備をすると，ターミナルから
```bash
$ ssh bdec
```

とするだけで，`wisteria.cc.u-tokyo.ac.jp` に接続できます．

さらに，EICへの接続設定も `config` ファイルに追記しましょう．

```bash
Host eic
     Hostname eic.eri.u-tokyo.ac.jp
     User USERNAME-of-EIC
     ProxyCommand ssh -W %h:%p bdec
     IdentityFile ~/.ssh/id_rsa
     ForwardX11 yes
```

Wisteria/BDECとほとんど同様ですが，`ProxyCommand` の行が増えています．これにより，`ssh eic` とするだけで，Wisteria/BDECを踏み台にしてEICに接続できます．

::: {.callout-note}
VSCodeでSSH拡張を利用している場合は，この設定ファイルが自動的に読み込まれます．
これ以降は，VSCodeからも `eic` を選択して接続できます．
:::
