---
title: 初回ログイン
date: 2025-05-11
date-modified: 2025-05-13
draft: true
abstract: "アカウント作成後のログイン方法について詳述します．"
---

## 2つのログインノードと選択

Miyabi はCPUによる計算ノードMiyabi-CとGPUによるノードMiyabi-Gの2つからなり，ログインノードもそれぞれに準備されています．どちらのログインノードも同じRed Hat Enterprise Linuxが稼働しているのですが，そのCPUが
Miyabi-Cではx86アーキテクチャのIntel Xeon，Miyabi-GではArmベースのNVIDIA Graceで，互いにバイナリの実行互換性がありません．

どちらのログインノードから入ってもファイルシステムは共通なうえ，たとえばMiyabi-GにログインしながらIntel CPU用の実行ファイルをコンパイルしてMiyabi-Cで実行させたり，あるいはその逆もできます．ただし，ソースコードのコンパイルはそれぞれのノードでしかできないようです．たとえば，NVIDIA環境でGPUコードのコンパイルをするためには，Miyabi-Gにログインしている必要があります．

自分のディレクトリ下で動作させるプログラム類はどちらかのアーキテクチャに統一しておいたほうが便利でしょうし，VSCodeでのSSH接続が自動的にホームディレクトリに作成する `.vscode-server` ディレクトリ内に自動作成されるファイルが原因で互換性の問題が発生し，接続ができなくこともあるようです．

そこで，Miyabi-CもしくはMiyabi-Gのどちらかを主なログイン先として選択し，VSCodeではそちらだけから接続するようにすることを勧めます．

ここでは，GPUの利用を重視してMiyabi-Gを選択し，そちらで環境の設営を行います．

## ログインまで

Miyabiのログインは公開鍵方式に二段階認証の一種であるワンタイムパスコード認証（OTP認証）を組み合わせたものです．公開鍵を作成していなければ，[こちら](../共通知識/Common-01-keys.md) の記事を参考に作成してください．そのうえで，[利用支援ポータル](https://miyabi-www.jcahpc.jp/login) から公開鍵をアップロードします．ただし，利用支援ポータルにログインするためには，OTP認証が必要です．詳しくは[東京大学情報基盤センターによる講習会資料](https://www.cc.u-tokyo.ac.jp/events/lectures/239/20250131_0217_login_miyabi.pdf)が詳しく参考になります（PDF中盤からログイン方法の説明があります．すでに公開鍵を作成済みであれば，前半の説明は飛ばして構いません．）．

::: {.callout-tip}
OTP認証のためには，スマートフォンアプリのGoogle AuthenticatorやMicrosoft Authenticatorが便利でしょう．どちらもiPhone/Androidともにアプリが提供されており，職場や学校のOfficeやGoogleアカウントのためにすでに使っている方も多いのではないかと思います．もしインストール済みでしたら，そこにMiyabi用のOTPを追加することができます．
:::

そうして公開鍵を登録したら，以下のコマンドでMiyabi-GにSSH接続してみます．ただし`username` は自分のアカウント名です．

```bash
ssh username@miyabi-g.jcahpc.jp
```

すると，QRコードとシークレットキーが表示されます．QRコードはOTP認証のためのアプリ（スマートフォン等）で読み取ることで，ログインノード接続のためのOTPを獲得できます．

::: {.callout-tip}
つまり，Miyabiへの接続には，利用支援ポータルとログインノードそれぞれのための，2つのOTP認証が必要となります．デフォルトではどちらもMiyabiとなり名前で区別しづらいので，適切名前をつけておくと良いかもしれません．
:::

::: {.callout-important}
シークレットキーはログインできなくなったときのアカウント復元に使うようです．別途保存しておいてください．
:::

ここまでで初回ログイン作業は終了です．あとは他のLinuxマシンと同じように，ログインノードの`.ssh/authorized_keys` ファイルに別のログイン元マシンの公開鍵（ `id_rsa.pub` の内容）を追加することで，他のマシンからも接続できるようになります．もちろん，利用支援ポータルから追加しても同じことです．

ここまでで設定したOTPは，Miyabi-CとMiyabi-Gで共通です．どちらのログインノードにも同じようにSSH接続できます．ログインノードは

- Miyabi-C: `miyabi-c.jcahpc.jp`
- Miyabi-G: `miyabi-g.jcahpc.jp`

です．接続元マシンの `~/.ssh/config` ファイルに

```bash
Host miyabi-g
    Hostname miyabi-g.jcahpc.jp
    User (username)
    IdentityFile ~/.ssh/id_rsa
    ForwardX11 yes
```

と設定しておくと，以降は

```bash
ssh miyabi-g
```

とOTP認証だけで接続できます．
