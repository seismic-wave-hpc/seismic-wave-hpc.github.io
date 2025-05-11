---
title: OpenSWPCのビルド
date: 2025-01-25
---

[公式マニュアル](https://OpenSWPC.github.io)にも記載のとおり，OpenSWPCは

- Fortran2008 対応のコンパイラ
- MPIライブラリ
- NetCDFライブラリ

があれば動作します．
利用する環境によってこれらのインストール先が異なるため，`src/shared/makefile.arch` ファイルにコンパイルのための設定を記載する方式を採用しています．

ここでは，動作を確認したいくつかの環境について，関連ライブラリのインストールと `makefile.arch` ファイルの設定について記載します．
