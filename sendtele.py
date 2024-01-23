#!/usr/bin/python3

from telegram import Bot
import asyncio
from datetime import datetime
from sys import argv


async def send_telegram_message(data):
    bot = Bot(token="6689916414:AAFllTz69WAqez9Wu5KsCgnDPP1yTIt-bsM")
    chat_id = "1112401247"
    message_text = data
    await bot.send_message(chat_id=chat_id, text=message_text, parse_mode='Markdown')

if __name__ == "__main__":
    msg = argv[1]
    if msg.endswith(".txt"):
        raw:list = []
        with open(msg, 'r') as lendomain:
            for x in lendomain.readlines():
                raw.append(x)
            len_d = len(raw)
        msgs = f"[INFO] {datetime.now()} - Wildhunt.sh started\n{len_d} domains"
        asyncio.run(send_telegram_message(msgs))
    elif msg.startswith("."):
        msgs = msg.replace('...', '')
        msgs = "[INFO] " + str(datetime.now()) + " : " + msg.replace('{nl}', '\n')
        asyncio.run(send_telegram_message(msgs))
    else:
        msgs = f"[INFO] {datetime.now()} -  {msg} now"
        asyncio.run(send_telegram_message(msgs))
