# 単語感情極性対応データベース格納用配列
def getDic1(filePath)
  list_db1 = Array.new
  File.open(filePath, 'r') do |file|
    file.each do |line|
      arr = line.chomp.split(':')
      list_db1 << {
        word: arr[0].downcase, # 単語
        reading: arr[1], # 読み
        pos: arr[2], # 品詞
        semantic_orientations: arr[3] # 感情値
      }
    end
  end

  return list_db1
end

# 日本語評価極性辞書データベース格納用配列(品詞や読みの情報がないので、単語と感情値のみ登録)
def getDic2(filePath1, filePath2)
  list_db2 = Array.new
  File.open(filePath1, 'r') do |file|
    file.each do |line|
      str = line.split(/\t/)
      list_db2 << {
        word: str[1].gsub(/( )/,"").gsub(/(\n)/,'').downcase,
        semantic_orientations: str[0].include?('ポジ') ? 1 : -1
      }
    end
  end

  File.open(filePath2, 'r') do |file|
    file.each do |line|
      str = line.split(/\t/)
      list_db2 << {
        word: normalize_neologd(str[0].gsub(/( )/,"").gsub(/(\n)/,'')).downcase,
        semantic_orientations: if str[1] == 'p' then 1 elsif str[1] == 'n' then -1 else 0 end
      }
    end
  end

  return list_db2
end

def getDicEmoji(filePath)
  json_data = open(filePath) do |io|
    JSON.load(io)
  end
  return json_data
end

def getDicIzon(filePath)
  list_dic = Array.new
  File.open(filePath, 'r') do |file|
    file.each do |line|
      str = line.split(",")
      list_dic << {
        word: str[0],
        semantic_orientations: str[1].to_i
      }
    end
  end
  return list_dic
end