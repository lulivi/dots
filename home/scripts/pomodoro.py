#!/usr/bin/env python3
"""Pomodoro timer module.

When runing this python module you will start a pomodoro timer. Each 25 minutes
of work you will get 5 minutes break. At the end of the 4th Pomodoro you will
get a longer break (15 minutes).
"""
import sys
import os
import time
import sched
import json
import urllib.request
import urllib.parse
from sched import Event
from urllib.error import HTTPError, URLError

from datetime import datetime
from typing import NamedTuple

DEFAULT_PRIORITY = 1
DELTA_START_TIME = 1 * 60
DELTA_POMODORO_TIME = 25 * 60
DELTA_SHORT_BREAK_TIME = 5 * 60
DELTA_LONG_BREAK_TIME = 15 * 60

scheduler = sched.scheduler(time.time, time.sleep)

try:
    BOT_TOKEN = os.environ["BOT_TOKEN"]
    CHAT_ID = os.environ["CHAT_ID"]
except KeyError:
    sys.exit("Ensure BOT_TOKEN and CHAT_ID variables are set.")


class Notification(NamedTuple):
    """Represents a notification.

    :ivar title: Notification's title.
    :ivar body: Notification's text body.
    """

    title: str
    body: str


def send_notification(notification: Notification):
    """Send telegram message through Telegram Bot API request.

    :param noticication: The :class:`Notification` to send.
    """
    print(
        "Notifying:\n"
        f"- Title: {repr(notification.title)}\n"
        f"- Body: {repr(notification.body)}"
    )
    bot_message = f"🍅 `{notification.title}` 🍅\n_{notification.body}_"
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    data = urllib.parse.urlencode(
        {"chat_id": CHAT_ID, "parse_mode": "Markdown", "text": bot_message}
    ).encode("ascii")
    request = urllib.request.Request(url, data)

    try:
        response = urllib.request.urlopen(request)
    except HTTPError as error:
        print("The server couldn't fulfill the request.")
        print("Error code: ", error.code)
        raise
    except URLError as error:
        print("We failed to reach a server.")
        print("Reason: ", error.reason)
        raise
    else:
        responsed_json = json.loads(response.read().decode("utf-8"))
        if not responsed_json.get("ok"):
            print("*" * 79)
            print(
                "Errorcete con el bot:\n"
                f"{json.dumps(responsed_json, indent=2)}"
            )
            print("*" * 79)


def clean():
    """Remove remaining jobs."""
    while not scheduler.empty():
        try:
            job = scheduler.queue[0]
            print(f"Cancelling job: {job}")
            scheduler.cancel(job)
        except ValueError:
            pass
    print("Finished all remaining jobs.")


def pomodoro_end_notification(
    current_stage: int, current_break_end_time: float
) -> Notification:
    """Obtain the notification for the next Pomodoro start.

    :param current_stage: Current index of Pomodoro.
    :param current_break_end_time: Ending time of the break in seconds since epoch.
    """
    next_pomodoro_string = time.strftime(
        "%H:%M:%S", time.localtime(current_break_end_time)
    )

    return Notification(
        f"Pomodoro[{current_stage}]::END",
        f"Next Pomodoro will start at {next_pomodoro_string}.",
    )


def break_end_notification(
    next_stage: int, next_pomodoro_end_time: float
) -> Notification:
    """Obtain the notification for the next break start.

    :param next_stage: Next index of Pomodoro.
    :param next_pomodoro_end_time: Ending time of the following Pomodoro in
        seconds since epoch.
    """
    next_break_string = time.strftime(
        "%H:%M:%S", time.localtime(next_pomodoro_end_time)
    )

    return Notification(
        f"Pomodoro[{next_stage}]::START",
        f"Starting a new Pomodoro. 🔨 GO 🔨 TO 🔨 WORK 🔨\n"
        f"Next break at {next_break_string}.",
    )


def schedule_pomodoro(current_stage: int) -> None:
    """Schedule one Pomodoro and it's break time.

    If we are in the forth stage of Pomodoro, we will take a longer break.

    :param current_stage: Current Pomodoro stage.
    """
    current_time = time.time()
    current_pomodoro_end_time = current_time + DELTA_POMODORO_TIME

    if current_stage == 4:
        next_stage = 1
        current_break_end_time = (
            current_pomodoro_end_time + DELTA_LONG_BREAK_TIME
        )
    else:
        next_stage = current_stage + 1
        current_break_end_time = (
            current_pomodoro_end_time + DELTA_SHORT_BREAK_TIME
        )

    next_pomodoro_end_time = current_break_end_time + DELTA_POMODORO_TIME

    # Pomodoro end notification: break start
    scheduler.enterabs(
        current_pomodoro_end_time,
        DEFAULT_PRIORITY,
        send_notification,
        argument=(
            pomodoro_end_notification(current_stage, current_break_end_time),
        ),
    )

    # Break end notification: next Pomodoro start
    scheduler.enterabs(
        current_break_end_time,
        DEFAULT_PRIORITY,
        send_notification,
        argument=(break_end_notification(next_stage, next_pomodoro_end_time),),
    )

    scheduler.run()
    schedule_pomodoro(next_stage)


def main() -> None:
    """Start the Pomodoro timer."""
    send_notification(
        Notification(
            "Pomodoro technique", "Starting Pomodoro in one minute..."
        )
    )

    next_stage = 1
    current_break_end_time = time.time() + DELTA_START_TIME
    next_pomodoro_end_time = current_break_end_time + DELTA_POMODORO_TIME
    scheduler.enterabs(
        current_break_end_time,
        DEFAULT_PRIORITY,
        send_notification,
        argument=(break_end_notification(next_stage, next_pomodoro_end_time),),
    )

    scheduler.run()
    schedule_pomodoro(next_stage)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        clean()
        sys.exit(f"There was an error: {str(error)}")
    except KeyboardInterrupt:
        print("Pressed Ctrl+c")
        clean()
        send_notification(
            Notification(
                "Pomodoro::TERMINATION", "Finishing Pomodoro timer..."
            )
        )
        sys.exit()
