# Chompy
Chompy the hipchat bot

A simple ruby-based HipChat bot.

## Installing
1. Clone this repo
2. Run `bundle install`
3. At the bottom of Chompy.rb, enter your HipChat API key
4. Also at the bottom of chompy.rb, enter the name of the chatroom you'd like Chompy to enter first
5. Run `ruby chompy.rb` to start Chompy.

## Features
Address Chompy in the chat as `chompy [command]`  

**Commands**  
`goto [room]`- Chompy will leave the current chatroom and go to the specified room.  
`showme [search term]` - Performs a google image search and posts the result to the room.  
`die` - Chompy stops obeying commands

## Roadmap
The next step was to add plugin support to Chompy. Unfortunately the company ran out of money, and I ran out of a job and access to HipChat.
So now Chompy is just some ruby code I put together one day.

