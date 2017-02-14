require 'twitter'
require 'natto'
require 'sqlite3'
require 'yaml'

require './lib/changeMoji.rb'
require './lib/getDictionary.rb'
require './lib/getTwListMembers.rb'

yml = YAML.load_file("./config.yml")
@client = Twitter::REST::Client.new do |config|
  config.consumer_key = yml['consumer_key']
  config.consumer_secret = yml['consumer_secret']
  config.access_token = yml['access_token']
  config.access_token_secret = yml['access_token_secret']
end

# TODO: バリデーションチェック未実装
maxCount = ARGV[0]
dicType = ARGV[1]

# 感情分析用辞書の配列
list_db1 = getDic1('./dic/pn_ja.dic')
list_db2 = getDic2('./dic/wago.121808.pn', './dic/pn.csv.m3.120408.trim')
# リストメンバーのツイッターIDを取得
members = getMembers('hashiva', 'sw')

# 結果を保存するDB
db = SQLite3::Database.new 'test.db'

# drop table
sql = <<-SQL
  DROP TABLE feel;
SQL
db.execute(sql)

# create table
sql = <<-SQL
  CREATE TABLE IF NOT EXISTS feel (
    id integer primary key,
    name text,
    avg integer,
    tweet text,
    dic text
  );
SQL
db.execute(sql)

def insertDB(db, name, avg, tweet, dic)
  puts [
         name,
         avg,
         tweet,
         dic
       ]
  # DBに登録
  db.execute('insert into feel (name, avg, tweet, dic) values (?, ?, ?, ?)', [name, avg, tweet, dic])
end

members.each do |member|

  # 特定ユーザのtimelineを取得
  list_tweets = Array.new
  @client.user_timeline(
    {
      screen_name: member,
      count: maxCount,
      exclude_replies: true,
      include_rts: false
    }
  ).each do |timeline|
    list_tweets << {
      screen_name: @client.status(timeline.id).user.screen_name,
      date: @client.status(timeline.id).created_at,
      tweet: @client.status(timeline.id).text,
      dictype: dicType
    }
  end

  list_morph = Array.new

  # ツイートを格納した配列から形態素分析
  list_tweets.each do |e|
    tmp = Array.new

    # 解析前に行う文字の正規化処理
    text = normalize_neologd "#{e[:tweet]}"
    text.downcase

    nm = Natto::MeCab.new(dicdir: "/usr/local/lib/mecab/dic/ipadic")
    nm.parse(text.encode("UTF-8")) do |n|
      next if n.is_eos?

      tmp << {
        word: n.surface, # 表層形
        reading: n.feature.split(',')[-2].tr('ァ-ン', 'ぁ-ん'), # 読み
        pos: n.feature.split(',')[0] # 品詞
      }
    end
    list_morph.push [tweet: text, morph: tmp]
  end

  # 各ツイートの感情分析
  list_semantic = Array.new
  list_morph.each do |e, i|
    tmp = Array.new
    e[:morph].each do |h|

      if dicType == 'dic1' or dicType == 'both' then
        list_db1.each do |line|
          # 単語、読み、品詞が一致の場合、感情値をカウント
          if h[:word] == line[:word] and h[:reading] == line[:reading] and h[:pos] == line[:pos] then
            tmp.push line[:semantic_orientations]
          end
        end
      end

      if dicType == 'dic2' or dicType == 'both' then
        list_db2.each do |line|
          if h[:word] == line[:word] then
            tmp.push line[:semantic_orientations]
          end
        end
      end
    end

    # sumを算出してDBに保存
    avg = tmp.inject(0){|sum, i| sum + i.to_f}
    insertDB(db, member, avg, e[:tweet], dicType)
  end

end
