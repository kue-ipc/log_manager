# ログマネージャー Log Manager

京都教育大学で使用しているツールが登録されています。
このツールも無償で利用することができます。

**ご利用に関するサポートはありません。**

ツールは「ありのまま」("AS IS")で提供されます。
利用者の責任のもとに、利用することができます。

## ライセンス

Copyright 2022-2023 Kyoto University of Education
The MIT License

## 動作環境

* Ruby 2.5以上、WindowsのみRuby 3.0以上
* gzip (zip_pwを使用する場合はPowerShellで代替可能)
* rsync (rsyncを使用する場合のみ)
* OpenSSH (scpを使用する場合のみ)

## 使い方

### インストール方法

1. 適当なところをに置きます。

2. `etc/log_manager.yml.sampl`を参考に`etc/log_manager.yml`を作成します。
    ファイルは、`/etc`、`/usr/local/etc`においてもいいです。

### 実行

`bin/lmg`がコマンドで、四つのコマンドが用意されています。

* `show`   ... 設定の表示する。
* `check`  ... ログディレクトリのディスクの空き容量をチェックする。
* `clean`  ... 古いログを圧縮・削除する。
* `rsync`  ... rsyncを用いてリモートからログファイルを取得する。
* `scp`    ... scp(ssh)を用いてリモートからログファイルを取得する。

c`-n`をつけるとファイルの変更がないモード(noop mode)になります。テストなどの確認に使ってください。また、`rsync`と`scp`については、`-h ホスト`でコピーするホストを指定できます。

### Windowsでの圧縮

デフォルトでは、圧縮にgzipコマンドを用いますが、Windows環境のためにPowerShell経由でZIP圧縮を行う`bin/zip_ps`を用意しています。PowerShellがインストールされていればLinuxでも使用可のです。

### SSHについて

`rsync`はSSHを利用します。`scp`と合わせてSSH環境を整えてください。

#### SSHの実行環境

コマンドの実行ユーザーのSSHの設定を利用します。そのユーザーがパスワード無しで各サーバーにアクセスできることを確認しておいてください。

#### セキュリティの注意事項

* 可能な限り、鍵はED25519を使用してください。
* 可能な限り、ログインユーザーはroot以外のユーザーにしてください。
* rootユーザーでログインする場合は、"sshd_config"でコマンド実行のみにしてください。

    ```sshd_config
    PermitRootLogin forced-commands-only
    ```

    どのようなアクセスでも"authorized_keys"の`command`に書かれたコマンドが実行されるようになります。また、"authorized_keys"の`from`でログサーバーを指定するようにしてください。

### rysncでの注意事項

リモート側にもrysncが必要です。インストールしておいてください。

通常、リモート側では次のようなコマンドが実行されます。

```shell
rsync --server --sender -vvulDtprze.iLsfxC . /remote/log/path/
```

最後の引数が同期元のディレクトリになります。これを`command`で指定しますが、同期元ディレクトリを複数書くこともできます。

```shell
rsync --server --sender -vvulDtprze.iLsfxC . /log1 /loge2
```

このようにすることで、複数のディレクトリと同期をとることができます。この時、ツールのコンフィグで設定している`dir`は無視されます。
