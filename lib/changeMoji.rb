require 'moji'

def normalize_neologd(norm)
  norm.tr!("０-９Ａ-Ｚａ-ｚ", "0-9A-Za-z")
  norm = Moji.han_to_zen(norm, Moji::HAN_KATA)
  hypon_reg = /(?:˗|֊|‐|‑|‒|–|⁃|⁻|₋|−)/
  norm.gsub!(hypon_reg, "-")
  choon_reg = /(?:﹣|－|ｰ|—|―|─|━)/
  norm.gsub!(choon_reg, "ー")
  chil_reg = /(?:~|∼|∾|〜|〰|～)/
  norm.gsub!(chil_reg, '')
  norm.gsub!(/[ー]+/, "ー")
  norm.tr!(%q{!"#$%&'()*+,-.\/:;<=>?@[¥]^_`{|}~｡､･｢｣"}, %q{！”＃＄％＆’（）＊＋，－．／：；＜＝＞？＠［￥］＾＿｀｛｜｝〜。、・「」})
  norm.gsub!(/　/, " ")
  norm.gsub!(/ {1,}/, " ")
  norm.gsub!(/^[ ]+(.+?)$/, "\\1")
  norm.gsub!(/^(.+?)[ ]+$/, "\\1")
  while norm =~ %r{([\p{InCjkUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+?)[ ]{1}([\p{InCjkUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+?)}
    norm.gsub!( %r{([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+?)[ ]{1}([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+?)}, "\\1\\2")
  end
  while norm =~ %r{([\p{InBasicLatin}]+)[ ]{1}([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)}
    norm.gsub!(%r{([\p{InBasicLatin}]+)[ ]{1}([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)}, "\\1\\2")
  end
  while norm =~ %r{([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)[ ]{1}([\p{InBasicLatin}]+)}
    norm.gsub!(%r{([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)[ ]{1}([\p{InBasicLatin}]+)}, "\\1\\2")
  end
  norm.tr!(
    %q{！”＃＄％＆’（）＊＋，－．／：；＜＞？＠［￥］＾＿｀｛｜｝〜},
    %q{!"#$%&'()*+,-.\/:;<>?@[¥]^_`{|}~}
  )
  norm
end

if $0 == __FILE__
  def assert(expect, actual)
    if expect == actual
      true
    else
      raise "Failed: Want #{expect.inspect} but #{actual.inspect}"
    end
  end
  assert "0123456789", normalize_neologd("０１２３４５６７８９")
  assert "ABCDEFGHIJKLMNOPQRSTUVWXYZ", normalize_neologd("ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ")
  assert "abcdefghijklmnopqrstuvwxyz", normalize_neologd("ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ")
  assert "!\"\#$\%&'()*+,-./:;<>?@[¥]^_`{|}", normalize_neologd("！”＃＄％＆’（）＊＋，−．／：；＜＞？＠［￥］＾＿｀｛｜｝")
  assert "＝。、・「」", normalize_neologd("＝。、・「」")
  assert "ハンカク", normalize_neologd("ﾊﾝｶｸ")
  assert "o-o", normalize_neologd("o₋o")
  assert "majikaー", normalize_neologd("majika━")
  assert "わい", normalize_neologd("わ〰い")
  assert "スーパー", normalize_neologd("スーパーーーー")
  assert "!#", normalize_neologd("!#")
  assert "ゼンカクスペース", normalize_neologd("ゼンカク　スペース")
  assert "おお", normalize_neologd("お             お")
  assert "おお", normalize_neologd("      おお")
  assert "おお", normalize_neologd("おお      ")
  assert "検索エンジン自作入門を買いました!!!", normalize_neologd("検索 エンジン 自作 入門 を 買い ました!!!")
  assert "アルゴリズムC", normalize_neologd("アルゴリズム C")
  assert "PRML副読本", normalize_neologd("　　　ＰＲＭＬ　　副　読　本　　　")
  assert "Coding the Matrix", normalize_neologd("Coding the Matrix")
  assert "南アルプスの天然水Sparking Lemonレモン一絞り", normalize_neologd("南アルプスの　天然水　Ｓｐａｒｋｉｎｇ　Ｌｅｍｏｎ　レモン一絞り")
  assert "南アルプスの天然水-Sparking*Lemon+レモン一絞り", normalize_neologd("南アルプスの　天然水-　Ｓｐａｒｋｉｎｇ*　Ｌｅｍｏｎ+　レモン一絞り")
end