require 'twitter'
require 'natto'
require 'sqlite3'
require 'yaml'

require './lib/changeMoji.rb'
require './lib/getDictionary.rb'
require './lib/getTwListMembers.rb'


# twitterアプリ登録時のkeyを指定(config.ymlに記載)
yml = YAML.load_file("./config.yml")
@client = Twitter::REST::Client.new do |config|
  config.consumer_key = yml['consumer_key']
  config.consumer_secret = yml['consumer_secret']
  config.access_token = yml['access_token']
  config.access_token_secret = yml['access_token_secret']
end

# TODO: バリデーションチェック未実装
# ** 指定必須
# 取得したいツイート数を指定(MAX 200)
maxCount = ARGV[0]

# ** 指定必須
# dic1:単語感情極性対応辞書を使用
# dic2:日本語評価極性辞書を使用
# both:両方使用
dicType = ARGV[1]

# ** 任意
# clean:データを全消去して取得し直し
# add:データ追加
# 指定なし:感情分析のみ
runType = ARGV[2]


# 感情分析用辞書の配列
list_db1 = getDic1('./dic/pn_ja.dic')
list_db2 = getDic2('./dic/wago.121808.pn', './dic/pn.csv.m3.120408.trim')
list_db3 = getDicEmoji('./dic/emoji_ios6.json')
list_db4 = getDicIzon('./dic/izon.csv')

# 取得したいツイッターID
members = getMembersFromFile('./twitterAcount.txt')


# 結果を保存するDB(sqlite3を使用)
db = SQLite3::Database.new 'test.db'
db.busy_timeout = 1000

def initForDB(db)
  db.execute('DROP TABLE feel;')

  # create table
  sql = <<-SQL
      CREATE TABLE IF NOT EXISTS feel (
        id INTEGER PRIMARY KEY,
        name TEXT,
        date TEXT,
        avg REAL,
        tweet TEXT,
        morph TEXT,
        wordavg TEXT,
        dic TEXT
      );
  SQL
  db.execute(sql)
end

# db.results_as_hash = true
db_tweet = db.execute("select * from feel")

if db_tweet.size.zero? or runType then

  if runType == 'clean'
    initForDB(db)
    puts runType
  end

  members.each_with_index do |member, i|
    
    # twitterのAPI制限を回避するために5人ずつ15分のインターバルを置く
    if i > 0 and i%5 == 0 then
      sleep 900
    end

    # 特定ユーザのtimelineを取得
    @client.user_timeline(
      {
        screen_name: member,
        count: maxCount,
        exclude_replies: true,
        include_rts: false
      }
    ).each do |timeline|
      tweet_obj = @client.status(timeline.id)
      h = {
        screen_name: tweet_obj.user.screen_name,
        date: tweet_obj.created_at.to_s,
        tweet: tweet_obj.text,
        dic: dicType
      }
      db.execute("insert into feel (name, date, tweet, dic) values (:screen_name, :date, :tweet, :dic)", h)
      puts tweet_obj.text

    end
  end
end

if runType == 'clean' or runType == "add" then
  exit
end

list_tweets = Array.new
db_tweet = db.execute("select * from feel")
db_tweet.each { |id, name, twdate, avg, tweet, dic|
  h = {
    id: id,
    screen_name: name,
    date: twdate,
    tweet: tweet,
    dic: dic
  }
  list_tweets << h
}

# ツイートを格納した配列から形態素分析
list_morph = Array.new
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

  list_morph << {id: e[:id], tweet: text, morph: tmp}
end


# 各ツイートの感情分析
list_morph.each_with_index do |e, index|
  tmp = Array.new
  avg_array = Array.new

  # 形態素解析の感情分析
  e[:morph].each do |h|

    # 機種依存文字判定
    list_db4.each do |k|
      if h[:word] == k[:word] then
        avg_array.push k[:semantic_orientations]
        tmp << {word: k[:word], avg: k[:semantic_orientations]}
      end
    end

    if h[:pos] == '記号' then
      h[:word].chars do |ch|
        list_db3.each do |line|
          if ch.encode("UTF-8").ord == line["codepoint"].hex then
            avg_array.push line["semantic"]
            tmp << {word: ch, avg: line["semantic"]}
            break
          end
        end
      end
    end

    if dicType == 'dic1' or dicType == 'both' then
      list_db1.each do |line|
        # 単語、読み、品詞が一致の場合、感情値をカウント
        if h[:word] == line[:word] and h[:reading] == line[:reading] and h[:pos] == line[:pos] then
          avg_array.push line[:semantic_orientations]
          tmp << {word: h[:word], avg: line[:semantic_orientations]}
          break
        end
      end
    end

    if dicType == 'dic2' or dicType == 'both' then
      list_db2.each do |line|
        if h[:word] == line[:word] then
          avg_array.push line[:semantic_orientations]
          tmp << {word: h[:word], avg: line[:semantic_orientations]}
          break
        end
      end
    end
  end

  # sumを算出してDBに保存
  p e[:id]
  avg = avg_array.inject(0) { |sum, k| sum + k.to_f }
  db.execute('update feel set avg = ?, morph = ?, wordavg = ? where id = ?', [avg, e[:morph].to_s, tmp.to_s, e[:id].to_i])
end
