#!/bin/bash
#
# iOSアプリの証明書とプロビジョニングプロファイルの有効期限が後何日で切れるかをSlackに通知
#

#---------------------------------
# 変数定義
#---------------------------------
dir_path="<.cer、.mobileprovisionファイルがあるディレクトリのフルパス>"

# Slack settings
webhookurl="<Webhook URL>"
channel="<channel名>"
username="iOS Certificates & Profiles Bot"
icon_emoji=":iphone:"
text=""

#警告メッセージを投稿する境目の日
warning_day=30

#---------------------------------
# 関数定義
#---------------------------------

# 後何日で有効期限が切れるかを返す関数
function get_days_left {
  # 有効期限(yyyy/mm/dd)
  local expiration_date=$1

  # 現在時刻をyyyy/mm/ddの形で取得
  local today=`date "+%Y/%m/%d"`

  local op_expire=`date +%s --date "${expiration_date}"`
  local op_today=`date +%s --date "${today}"`

  # 後何日で有効期限が切れるかを計算して返す
  echo "scale=0; ($op_expire - $op_today) / 3600 / 24" | bc
}

# Slackに投稿する関数
function post_to_slack {
  local name=$1
  local days_left=$2
  local expiration_date=$3

  # 通常の文言
  text="*""${name}""* は後 *""${days_left}""日* で有効期限が切れます。(有効期限：""${expiration_date}"")"

  # 30日以内に有効期限が切れる場合は、アイコンと文言を変える
  if [ "${days_left}" -le "${warning_day}" ] ; then
    icon_emoji=":exclamation:"
    text="<!here> やばいよ、やばいよ！ *""${name}""* は後 *""${days_left}""日* で有効期限が切れちゃうよ！早く証明書を更新して！！(有効期限：""${expiration_date}"")"
  fi

  # おまけ
  if [ "${days_left}" -lt 0 ] ; then
    icon_emoji=":innocent:"
    text="*""${name}""* の有効期限？それならもう切れちゃったよ... (有効期限：""${expiration_date}"")"
  fi

  # Slackに投稿
  curl -X POST --data-urlencode "payload={\"channel\": \"${channel}\", \"username\": \"${username}\", \"icon_emoji\": \"${icon_emoji}\", \"text\": \"${text}\"}" ${webhookurl}
}
#---------------------------------
# main
#---------------------------------

# git pullする
cd ${dir_path}
git pull

# ディレクトリ内の各.cerに適用
find ${dir_path} -type f -name '*.cer' -print    |
while read cer_path
do
  # ファイル名を取得
  cer_name=`basename ${cer_path}`

  # iOSアプリ証明書の有効期限を取得
  expiration_time=`openssl x509 -inform der -noout -dates -in "${cer_path}" | grep '^notAfter=' | sed -e 's/^notAfter=//'`
  # 有効期限をyyyy/mm/ddの形にする
  expiration_date=`date --date "${expiration_time}" "+%Y/%m/%d"`

  # 有効期限が後何日で切れるかを取得
  days_left=`get_days_left "${expiration_date}"`

  # Slackに通知
  post_to_slack "${cer_name}" "${days_left}" "${expiration_date}"
done

# ディレクトリ内の各.mobileprovisionに適用
find ${dir_path} -type f -name '*.mobileprovision' -print    |
while read profile_path
do
  # ファイル名を取得
  profile_name=`basename ${profile_path}`

  # iOSアプリ証明書の有効期限を取得
  expiration_time=`openssl smime -inform der -verify -noverify -in "${profile_path}" | grep -A1 ExpirationDate | grep '<date>' | sed 's/<date>\(.*\)<\/date>/\1/'`
  # 有効期限をyyyy/mm/ddの形にする
  expiration_date=`date --date "${expiration_time}" "+%Y/%m/%d"`

  # 有効期限が後何日で切れるかを取得
  days_left=`get_days_left "${expiration_date}"`

  # Slackに通知
  post_to_slack "${profile_name}" "${days_left}" "${expiration_date}"
done
