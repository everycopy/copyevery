#!/usr/bin/env ruby

require 'twitter_ebooks'
require 'yaml'

# Put the keys and whatnot in their own config file like waferbaby does
# https://github.com/waferbaby/waferbot/blob/master/bots.rb
config = YAML::load_file('config.yml')

Ebooks::Bot.new("bot") do |bot|
  bot.consumer_key = config['consumer_key']
  bot.consumer_secret = config['consumer_secret']
  bot.oauth_token = config['oauth_token']
  bot.oauth_token_secret = config['oauth_token_secret']

  bot.on_mention do |tweet, meta|
    # Reply to a mention
    model = Ebooks::Model.load("model/everycopy.model")
    bot.reply(tweet, meta[:reply_prefix] + model.make_statement(100))
  end

  bot.on_timeline do |tweet, meta|
    # Reply to a tweet in the bot's timeline
    model = Ebooks::Model.load("model/everycopy.model")
    bot.reply(tweet, meta[:reply_prefix] + model.make_statement(100))
  end

  bot.scheduler.every '24h' do
    # Tweet something every 24 hours
    model = Ebooks::Model.load("model/everycopy.model")
    bot.tweet(model.make_statement(140))
  end
end
