# ログマネージャー Log Manager

京都教育大学で使用しているツールが登録されています。
このツールも無償で利用することができます。

**ご利用に関するサポートはありません。**

ツールは「ありのまま」("AS IS")で提供されます。
利用者の責任のもとに、利用することができます。

## ライセンス

Copyright 2022 Kyoto University of Education
The MIT License

## 動作環境

* Ruby 2.0 以上
* gzip
* rsync
* OpenSSH (ssh, scp)

## 使い方

### インストール方法

1. 適当なところをに置きます。

2. `etc/log_manager.yml.sampl`を参考に`etc/log_manager.yml`を作成します。
    ファイルは、`/etc`、`/usr/etc`、`/usr/local/etc`においてもいいです。

### 実行

`bin/lmg`がコマンドで、四つのサブコマンドが用意されています。

* `lmg config` ... 設定の表示する。
* `lmg clean`  ... 古いログを圧縮・削除する。
* `lmg rsync`  ... rsyncを用いてリモートからログファイルを取得する。
* `lmg scp`    ... scp(ssh)を用いてリモートからログファイルを取得する。

config以外では`-n`をつけるとファイルの変更がないモード(noop mode)になります。テストなどの確認に使ってください。また、rsyncとscpでは`-h ホスト`でホスト指定もできます。

### SSHについて

rsyncはSSHを利用します。scp(ssh)と合わせてSSH環境を整えてください。

#### SSHの実行環境

コマンドの実行ユーザーのSSHの設定を利用します。そのユーザーがパスワード無しで各サーバーにアクセスできることを確認しておいてください。

#### セキュリティの注意事項

* 可能な限り、鍵はED25519を使用してください。
* 可能な限り、ログインユーザーはroot以外のユーザーにしてください。
* rootユーザーでログインする場合は、"sshd_config"でコマンド実行のみにしてください。

    ```
    PermitRootLogin forced-commands-only
    ```

    どのようなアクセスでも"authorized_keys"の`command`に書かれたコマンドが実行されるようになります。また、"authorized_keys"の`from`でログサーバーを指定するようにしてください。

### rysncでの注意事項

リモート側にもrysncが必要です。インストールしておいてください。

通常、リモート側では次のようなコマンドが実行されます。

```
rsync --server --sender -vvulDtprze.iLsfxC . /remote/log/path/
```

最後の引数が同期元のディレクトリになります。これを`command`で指定しますが、同期元ディレクトリを複数書くこともできます。

```
rsync --server --sender -vvulDtprze.iLsfxC . /log1 /loge2
```

このようにすることで、複数のディレクトリと同期をとることができます。この時、ツールのコンフィグで設定している`dir`は無視されます。
