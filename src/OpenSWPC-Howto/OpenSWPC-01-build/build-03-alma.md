## AlmaLinux

[AlmaLinux](https://almalinux.org/ja/) は，いわゆるRedHat系のLinuxディストリビューションです．[Red Hat Enterprise Linux](https://www.redhat.com/ja/technologies/linux-platforms/enterprise-linux) (RHEL) は非常に有名なLinuxディストリビューションで，商用（有償）ですがその分サポートがつくということもあり，業務系のシステムで多く使われているようです．

一方，Linuxのカーネルパッケージは[GPL (GNU General Public License)](https://www.gnu.org/licenses/gpl-3.0.html) のもとで開発されているため，ライセンスの定めるところにより，RHELもまたそのソースコードが公開されていました．その公開されたソースコードを元にして，数多くのオープンソースのLinuxディストリビューションが開発されてきました．そのような一連のディストリビューションは，Red Hat系ディストリビューションと呼ばれています．

数多くのRed Hat系ディストリビューションのなかで，[CentOS](https://www.centos.org) が長らくもっとも広く使われるディストリビューションであり続けました．しかし，2020年12月にCentOSの開発停止がアナウンスされ，2024年6月30日にはCentOS 7のサポートが終了しました．CentOSグループは新たにCentOS Streamというディストリビューションを公開していますが，これはRHELのテスト版のような位置づけであり，安定性に欠くため日常的な利用目的にはあまり推奨できません．

このような（やや混乱した）状況を受けて，CentOSサポート終了後の後継とみなされているRHEL互換のLinuxディストリビューションの一つがAlma Linuxです．以下ではAlmaLinux9.5で動作確認をしたビルド方法を紹介しますが，多くおRed Hat系のディストリビューションで同様にビルドできると期待されます．

### AlmaLinuxにおけるビルド

AlmaLinuxのパッケージ管理システムは `yum` と `dnf` ですが，デフォルトのパッケージ一覧の中には科学技術計算に関するライブラリ群が十分に含まれていません．そこで，まず [Extra Packages for Enterprise Linux (EPEL)](https://docs.fedoraproject.org/en-US/epel/) リポジトリを有効化します．これはRHEL系ディストリビューションの一つであるFedora Projectで開発された追加パッケージの一覧です．

```bash
sudo dnf config-manager --set-enabled crb 
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
sudo dnf update
```

そのうえで関連パッケージをインストールします．

::: {.callout-note}
昔からのRHEL系ディストリビューションのユーザーは `yum` コマンドに慣れ親しんでいるかと思います．`dnf` は `yum` の後継として開発されたパッケージ管理コマンドで，2025年時点では`yum`も`dnf`もどちらもコマンドとしては有効になっていますが，実際には `yum` は `dnf` のシンボリックリンクになっていて，パッケージ管理コマンドは事実上 `dnf` に一本化されているようです．
:::

その後で関連ライブラリのインストールをします．

```bash
sudo yum install gfortran
sudo yum install openmpi openmpi-devel
sudo yum install netcdf netcdf-fortran netcdf-devel netcdf-fortran-devel
sudo yum install git curl
```

Ubuntu Linuxと同様に，openmpiやnetcdfの本体と開発用のライブラリは別パッケージとなっていますので，ご注意ください．

なお，AlmaLinuxではOpenMPIはインストールしても `mpif90` や `mpirun` 等のコマンドにPATHが通らないようです．そのため，`.bashrc` ファイル等に以下のようにインストール先 `/usr/lib64/openmpi/bin/` にPATHを設定するコマンドを記述するか，あるいはコンパイルおよび実行時にPATHつきでコマンドを実行することになります．

```bash
# この設定を ~/.bashrc に記載する
export PATH=${PATH}:/usr/lib64/openmpi/bin/
```

OpenSWPCのビルドでは，（少なくとも v25.01時点では）デフォルト設定にAlmaLinuxが含まれていないため，自分で `makefile.arch` を編集する必要があります．

```{.makefile filename="src/shared/makefile.arch"}
ifeq ($(arch), almalinux)
    FC     = /usr/lib64/openmpi/bin/mpif90
    FFLAGS = -O2 -ffast-math -fopenmp -cpp
    NCLIB  = -L/usr/lib64
    NCINC  = -I/usr/lib64/gfortran/modules
    NETCDF = -lnetcdf -netcdff
endif
```

```{.makefile filename="src/shared/makefile-tools.arch"}
ifeq ($(arch), almalinux)
    FC     = gfortran
    FFLAGS = -O2 -ffast-math -fopenmp -cpp
    NCLIB  = -L/usr/lib64
    NCINC  = -I/usr/lib64/gfortran/modules
    NETCDF = -lnetcdf -netcdff
endif
```

`makefile.arch`と`makefile-tools.arch`それぞれを上記のように編集してから

```bash
cd src
make arch=almalinux
```

とすることでビルドできます．

`swpc_sh.x`, `swpc_psv.x`, `swpc_3d.x` をMPI実行する場合には，前述の `export PATH...` 設定をしておくか，あるいは実行時に

```bash
/usr/lib64/openmpi/bin/mpirun -np 4 ./bin/swpc_3d.x -i example/input.inf
```

のように `mpirun` コマンドを場所つきで指定する必要があります．
