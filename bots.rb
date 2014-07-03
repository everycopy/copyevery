#!/usr/bin/env ruby

require 'twitter_ebooks'
require 'yaml'

# Put the keys and whatnot in their own config file like waferbaby does
# https://github.com/waferbaby/waferbot/blob/master/bots.rb
config = YAML::load_file('config.yml')

# Choose which text model we want to use
model = Ebooks::Model.load("model/" + config['text_model_name'] + ".model")

# Simulated human reply delay range in seconds
# https://github.com/mispy/ebooks_example
DELAY = 10..30

# Track who we've randomly interacted with globally
$have_talked = {}

Ebooks::Bot.new(config['twitter_username']) do |bot|
  bot.consumer_key = config['consumer_key']
  bot.consumer_secret = config['consumer_secret']
  bot.oauth_token = config['oauth_token']
  bot.oauth_token_secret = config['oauth_token_secret']

  bot.on_message do |dm|
    # Reply to a DM
    length = dm[:text].length

    bot.delay DELAY do
      bot.reply(dm, model.make_response(dm[:text], 140-length))
    end
  end

  bot.on_follow do |user|
    # Follow a user back
    bot.delay DELAY do
      bot.follow(user[:screen_name])
    end
  end

  bot.on_mention do |tweet, meta|
    # Avoid infinite reply chains (very small chance of crosstalk)
    next if tweet[:user][:screen_name].include?(config['robot_id']) && rand > 0.05
    next if rand < 0.05

    # Any given user will receive at most one random interaction per day
    next if $have_talked[tweet[:user][:screen_name]]
    $have_talked[tweet[:user][:screen_name]] = true

    # Reply to a mention
    length = tweet[:text].length + meta[:reply_prefix].length
    response = model.make_response(tweet[:text], 140 - length)

    bot.delay DELAY do
      bot.reply(tweet, meta[:reply_prefix] + response)
    end
  end

  bot.on_timeline do |tweet, meta|
    next if tweet[:retweeted_status] || tweet[:text].start_with?('RT')
    next unless rand < 0.05

    # Reply to a tweet in the bot's timeline
    length = tweet[:text].length + meta[:reply_prefix].length
    response = model.make_response(tweet[:text], 140 - length)

    bot.delay DELAY do
      bot.reply(tweet, meta[:reply_prefix] + response)
    end
  end

  bot.scheduler.every '12h' do
    # Tweet something every 24 hours
    bot.tweet(model.make_statement(140))
    $have_talked = {}
  end
end
