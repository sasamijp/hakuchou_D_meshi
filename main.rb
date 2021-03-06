# -*- coding: utf-8 -*-

require 'twitter'
require 'date'
require 'nkf'
require './key.rb'


@rest_client = Twitter::REST::Client.new do |config|
  config.consumer_key        = Const::CONSUMER_KEY
  config.consumer_secret     = Const::CONSUMER_SECRET
  config.access_token        = Const::ACCESS_TOKEN
  config.access_token_secret = Const::ACCESS_TOKEN_SECRET
end

@stream_client = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = Const::CONSUMER_KEY
  config.consumer_secret     = Const::CONSUMER_SECRET
  config.access_token        = Const::ACCESS_TOKEN
  config.access_token_secret = Const::ACCESS_TOKEN_SECRET
end


@dic         = {'朝' => 'first', '昼' => 'second', '夜' => 'third'}
@last_update = nil
@name        = Const::SCREEN_NAME


def meshi(status)


  
  matchd = status.match(/@#{@name} ([0-9]+|今|明|明々*後)日[ の]?(.)/)
  return unless matchd
  
  specified_day  = matchd[1]
  specified_time = matchd[2]

  date    = Date.today
  end_day = Date.new(date.year, date.month, -1).day

  if date.day == end_day
    raise "今日は月末です。献立表の更新までお待ちください。"
  end

  if specified_day =~ /[0-9]+/
    if day > end_day
      return
    end
    day = specified_day.to_i
  else
    d   = date.day
    day = d + 0
    day = d + 1 if speciefid_day == "明"
    day = d + 2 +  speciefid_day.count("々") if speciefid_day =~ /明々*後/
  end
  
  menu = "./#{@dic[specified_time]}.txt"
  
  return File.readlines(menu)[day - 1].chomp

end


def tweet(body ,object = nil)
  
  unless object
    opt = nil
    tweet = body
  else
    opt = {"in_reply_to_status_id" => object.id.to_s}
    tweet = "@#{object.user.screen_name} #{body}"
  end
  
  @rest_client.update tweet,opt
  
end


def follow
  
  follower_ids = []
  @rest_client.follower_ids("#{@name}").each do |id|
    follower_ids.push(id)
  end
  
  friend_ids   = []
  @rest_client.friend_ids("#{@name}").each do |id|
    friend_ids.push(id)
  end
  
  protect_ids  = []
  @rest_client.friendships_outgoing.each do |id|
    protect_ids.push(id)
  end

  @rest_client.follow(follower_ids - friend_ids - protect_ids)

end


def auto
  
  d     = DateTime.now
  today = Date.today
  
  return if @last_update and @last_update.hour == d.hour
  
  time = "朝" if d.hour == 07
  time = "昼" if d.hour == 11
  time = "夜" if d.hour == 17
  follow      if d.hour == 00
  
  menu = "./#{@dic[time]}.txt"

  today_menu = File.readlines(menu)[today.day - 1].chomp
  
  body = "#{d.month}月#{d.day}日の#{time}の献立は#{today_menu}です。"
  tweet(body) if time
  
  @last_update = d    
  
end


Thread.new(){
  while true
    puts "ok #{DateTime.now}"
    auto
    sleep(10)
  end
}


@stream_client.user do |object|
  next unless object.is_a? Twitter::Tweet
  unless object.text.start_with? "RT"
    begin
      tweet_body = meshi(object)
    rescue => e
      puts e
      tweet_body = e
    ensure
      tweet(tweet_body, object)
    end
  end
end
