git clone https://github.com/tfutils/tfenv.git ~/.tfenv

.bashrcに環境変数を設定
nano ~/.bashrc

export PATH="$HOME/.tfenv/bin:$PATH"

環境変数の反映
source ~/.bashrc

tfenv -v

# インストール可能なバージョンを表示
tfenv list-remote

# バージョンを指定してインストール
VERSION=1.0.0
tfenv install ${VERSION}

# バージョンの切り替え
tfenv use ${VERSION}

# auto completeの設定
terraform -install-autocomplete

tflintのインストール
curl https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash