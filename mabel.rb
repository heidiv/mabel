#!/usr/bin/env ruby

class Mabel
  require 'net/http'
  require 'net/https'
  require "uri"
  require "twitter"
  
  # Set up twitter client
  def initialize      
    @mytwitter = Twitter::REST::Client.new do |config|
      config.consumer_key        = "YOUR CONSUMER KEY"
      config.consumer_secret     = "YOUR CONSUMER SECRET"
      config.access_token        = "YOUR TOKEN"
      config.access_token_secret = "YOUR TOKEN SECRET"
    end            
  end  
  
  # Create twitter message
  def make_message (test_user, test_result)
    msg_prefixes = [  
      "Doh! ",
      "Ruh roh. ", 
      "Oops! ",
      "Let's get this fixed! ",
      "Hmm, this isn't good. ",
      "Better get this fixed! ",
      "Beep boop! ",
      "FYI! ",
      "Something to work on! ",
      "One for the to-do list! ",
      "A problemo. ",
      "Needs some love... "
    ]
            
    msg = test_user + " " + msg_prefixes.sample + "Issue found on your site. " + test_result['resultTitle']
    msg.gsub! '&lt;', '<'
    msg.gsub! '&gt;', '>' 
    msg.gsub! '`', '' 
    return msg
  end

  # Send a Mabel tweet
  def send_tweet      
    # Slurp handles file
    handles = IO.readlines "accts.txt"
    test_user = handles.sample.to_s.strip
    
    # Get account's URL
    test_url = @mytwitter.user(test_user).website
    
    # Test URL for accessibility
    @results = test_a11y(test_url)        
    
    if @results['status'] != 200
      return
    end

    # Create message from one of the issues found, if any
    if @results['resultSet'].any?                               
      mabel_tweet = make_message(test_user, @results['resultSet'].sample)            
      until (mabel_tweet.length <= 140)
        mabel_tweet = make_message(test_user, @results['resultSet'].sample)      
      end
    else
      mabel_tweet = "Robot dance. No obvious accessibility errors detected at " + test_user + "'s website! #a11y" 
    end
    
    # Rewrite accts.txt minus user
    open("accts.txt", 'w') do |f|
      handles.each do |handle|
        if handle.strip != test_user
          f.puts handle
        end
      end
    end
    
    # Write user to accts_tweeted.txt, for reference     
    open("accts_tweeted.txt", 'a') do |f|
      f.puts test_user
    end

    # Mabel tweets the message
    @mytwitter.update(mabel_tweet)             
  end 

  # Receives a URL to test using Tenon API, returns results
  def test_a11y(url)
    data = {
      url: url,
      key: "YOUR TENON KEY",
      level: "AA"
    }

    uri = URI.parse('https://tenon.io/api/')
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(data)
    response = https.request(request)    

    return JSON.parse(response.body)
  end  
end

if __FILE__ == $0
  mabel = Mabel.new
  mabel.send_tweet
end
