require 'twitter'
require 'yaml'

yml = YAML.load_file("./config.yml")
@client = Twitter::REST::Client.new do |config|
  config.consumer_key = yml['consumer_key']
  config.consumer_secret = yml['consumer_secret']
  config.access_token = yml['access_token']
  config.access_token_secret = yml['access_token_secret']
end

# リストのメンバーを取得する
def getMembersFromAPI(userName, listName)
  # ユーザが作成したリスト
  @client.owned_lists(userName, {count: 10}).each do |list|
    if list.name == listName then
      @sw_list_id = list.id
    end
  end

  members = Array.new
  @client.list_members(@sw_list_id, count: 1000).each do |user|
    members.push user.screen_name
  end
  return members
end

def getMembersFromFile(filePath)
  members = Array.new
  File.open(filePath, 'r') do |file|
    file.each do |line|
      members << line
    end
  end
  return members
end
