## agnellopio-tg v0.20
## Requires editing to get this working correctly, code is here as a PoC
## of MegaHAL running on a Telegram bot.
##
## Source is distributed under the AGPL v3.0
## https://www.gnu.org/licenses/agpl-3.0.html
## 
## Contributions to the code are welcome.

require 'telegram/bot'
require 'megahal'

## CONFIGURATION START ##
token = 'INSERT_YOUR_BOT_TOKEN_HERE'
## CONFIGURATION END ##

ai = MegaHAL.new()
bot_id = token.split(":").at(0).to_i

if File.file?("agnellopio.brn") then
  ai.load("agnellopio.brn")
end

$save_counter = 0

def save_private_ryan(real_ai)
  if $save_counter > 20 then
	File.delete("agnellopio.bak") rescue puts "Cannot delete backup."
    File.rename("agnellopio.brn", "agnellopio.bak") rescue puts "Cannot rename actual brain."

    real_ai.save("agnellopio.brn")
	puts "Brain saved."
	
	$save_counter = 0
  end
  
  $save_counter += 1
end

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message
	when Telegram::Bot::Types::InlineQuery
	  if message.query.end_with? "." then
	    puts "Processing inline query -- #{message.query}"
		
	    results = [
          [1, 'Diventa una divinità', 'Impossibile resistere.'],
        ].map do |arr|
          Telegram::Bot::Types::InlineQueryResultArticle.new(
            id: arr[0],
            title: arr[1],
            input_message_content: Telegram::Bot::Types::InputTextMessageContent.new(message_text: ai.reply(message.query))
          )
        end

        bot.api.answer_inline_query(inline_query_id: message.id, results: results)
	    save_private_ryan(ai)
	  else
	    next
	  end
	when Telegram::Bot::Types::Message
      reply = nil
	  text = message.text.dup rescue ''
	
	  # Remove the bot's name and /start from the message going to be learnt
	  text.slice! "@AgnelloPio_bot"
	  text.slice! "/start"
	
	  puts "Processing message -- #{text}"
	
	  # Placeholder
	  if message.text =~ /\/start/i then
	    reply = "/start, /start e ancora /start, maledizione!"
	    bot.api.send_message(chat_id: message.chat.id, text: reply, reply_to_message_id: message.message_id)
	    next
	  end
	  
      # Triggers
      if message.text =~ /@AgnelloPio_bot/i then
	    reply = ai.reply(text)
	    bot.api.send_message(chat_id: message.chat.id, text: reply, reply_to_message_id: message.message_id)
	    save_private_ryan(ai)
	    next
	  end

	  if message.text =~ /agnello/i then
	    reply = ai.reply(text)
	    bot.api.send_message(chat_id: message.chat.id, text: reply, reply_to_message_id: message.message_id)
	    save_private_ryan(ai)
	    next
	  end
	  # End triggers
	
	  # Reply
	  if message.reply_to_message then
	    # Is that really mentioning me?
	    if message.reply_to_message.from.id == bot_id then
	      reply = ai.reply(text)
	      bot.api.send_message(chat_id: message.chat.id, text: reply, reply_to_message_id: message.message_id)
	      save_private_ryan(ai)
	      next
	    end
	  end
	
	  # Private message: reply anyways
	  if message.chat.type == "private" then
	    reply = ai.reply(text)
	    bot.api.send_message(chat_id: message.chat.id, text: reply, reply_to_message_id: message.message_id)
	    save_private_ryan(ai)
	    next
	  end
	
	  # Hack: learn the rest discarding the result
	  discard = ai.reply(text)
	  save_private_ryan(ai)
	else
	  next
    end
  end
end
