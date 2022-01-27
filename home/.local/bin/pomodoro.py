#!/usr/bin/env python3
"""Pomodoro timer.

When runing this python module you will start a pomodoro timer. Each 25 minutes
of work you will get 5 minutes break. At the end of the 4th Pomodoro you will
get a longer break (15 minutes).

It is possible to run the timer within a new process or the main one. This is
just for demostrating purposes in case you want to run the timer while running
other code.

.. code-block:: console

    pomodoro.py

.. code-block:: console

    pomodoro.py --notifier desktop

"""
import argparse
import json
import logging
import multiprocessing
import os
import sched
import sys
import time
import urllib.parse
import urllib.request

from enum import Enum
from os import environ
from sched import Event
from typing import Callable, Dict, List, Optional
from urllib.error import HTTPError, URLError

TG_BOT_TOKEN = ""
TG_MY_ID = ""


class Notifier(Enum):
    TELEGRAM = 0
    DESKTOP = 1
    ALL = 2


def send_desktop_notification(title: str, body: str = "") -> None:
    """Send a desktop notificatino with the title and body provided.

    :param title: title of the notification.
    :param body: body of the notification.

    """
    if not title:
        print("Error sending notification: no title provided.")
        return

    os.system(f"notify-send '{title}' '{body}'")


def send_telegram_notification(title: str, body: str = "") -> None:
    """Send a telegram notification with the title and body provided.

    :param title: title of the notification.
    :param body: body of the notification.

    """
    if not title:
        print("Error sending notification: no title provided.")
        return

    bot_message = f"🍅 `{title}` 🍅\n_{body}_"

    url = f"https://api.telegram.org/bot{TG_BOT_TOKEN}/sendMessage"
    data = urllib.parse.urlencode(
        {
            "chat_id": TG_MY_ID,
            "parse_mode": "Markdown",
            "text": bot_message,
        }
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
            print(f"Errorcete con el bot:\n{json.dumps(responsed_json, indent=2)}")
            print("*" * 79)


class PomodoroTimer(object):
    """Pomodoro timer.

    This class allow to run a Pomodoro Timer notifying when time slots expire.

    :ivar __time_callable: :func:`time.time`-like callable to manage sheduled
        events and notify current time.
    :ivar __scheduler: :class:`sched.scheduler` instance for performing timer
        operations.
    :ivar __notification_callable: callable with ``title`` and ``body`` as
        arguments to call when a timer ends.
    :ivar __logger: optional :class:`logging.Logger` instance to log info.
    :cvar DEFAULT_PRIORITY: default scheduler priotiry.
    :cvar DELTA_START_TIME: timer wait until first pomodoro starts after
        starting the timer.
    :cvar DELTA_POMODORO_TIME: each pomodoro time span.
    :cvar DELTA_SHORT_BREAK_TIME: short breaks time span.
    :cvar DELTA_LONG_BREAK_TIME: long breaks time span.

    """

    DEFAULT_PRIORITY: int = 1
    DELTA_START_TIME: int = 1 * 60
    DELTA_POMODORO_TIME: int = 25 * 60
    DELTA_SHORT_BREAK_TIME: int = 5 * 60
    DELTA_LONG_BREAK_TIME: int = 15 * 60

    def __init__(
        self,
        notification_callable: Optional[Callable[[str, str], None]] = None,
        time_callable: Callable[[], float] = time.time,
        sleep_callable: Callable = time.sleep,
        logger: Optional[logging.Logger] = None,
    ):
        """Pomodoro timer constructor.

        :param notification_callable: callable to send notifications with.
        :param time_callable: time-like function callable.
        :param sleep_callable: sleep-like function callable.
        :param logger: information logger.

        """
        self.__time_callable: Callable[[], float] = time_callable
        self.__scheduler: sched.scheduler = sched.scheduler(time_callable, sleep_callable)
        self.__notification_callable: Callable[[str, str], None] = notification_callable or (
            lambda title, body: print(title, body, sep="\n")
        )
        self.__logger: Optional[logging.Logger] = logger
        self.__stop_scheduler: bool = False

    def __log(self, message: str) -> None:
        """Log message if logger exists.

        :param message: message to log.

        """
        if self.__logger:
            self.__logger.debug(message)

    def __notify(self, title: str, body: str = "") -> None:
        """Log and send the notification.

        :param title: title of the notification.
        :param body: body of the notification.

        """
        self.__log(f"Sending notification. Title='{title}', Body='{body}'")
        self.__notification_callable(title, body)

    def __clean_jobs(self) -> None:
        """Clean remaining jobs."""
        while not self.__scheduler.empty():
            try:
                job: sched.Event = self.__scheduler.queue[0]
                self.__log(f"Cancelling job: {job}")
                self.__scheduler.cancel(job)
            except ValueError:
                pass
        else:
            self.__log("All jobs are finished.")

    def __pomodoro_end_notification(
        self, current_stage: int, current_break_end_time: float
    ) -> Dict[str, str]:
        """Obtain the notification for the next Pomodoro start.

        :param current_stage: current index of Pomodoro.
        :param current_break_end_time: ending time of the break in seconds
            since epoch.
        :returns: notification to send when the current pomodoro ends.

        """
        next_pomodoro_string: str = time.strftime("%H:%M", time.localtime(current_break_end_time))

        return {
            "title": f"POM[{current_stage}]::END. Next pomodoro at {next_pomodoro_string}.",
        }

    def __break_end_notification(
        self, next_stage: int, next_pomodoro_end_time: float
    ) -> Dict[str, str]:
        """Obtain the notification for the next break start.

        :param next_stage: Next index of Pomodoro.
        :param next_pomodoro_end_time: Ending time of the following Pomodoro in
            seconds since epoch.
        :returns: notification to send when the current break ends.

        """
        next_break_string: str = time.strftime("%H:%M", time.localtime(next_pomodoro_end_time))

        return {"title": f"POM[{next_stage}]::START. Next break at {next_break_string}."}

    def __schedule_pomodoro(self, current_stage: int) -> None:
        """Schedule one Pomodoro and it's break time.

        If we are in the forth stage of Pomodoro, we will take a longer break.

        :param current_stage: current Pomodoro stage
        """
        current_time: float = self.__time_callable()
        current_pomodoro_end_time: float = current_time + self.DELTA_POMODORO_TIME
        next_stage: int
        current_break_end_time: float
        next_pomodoro_end_time: float

        if current_stage == 4:
            next_stage = 1
            current_break_end_time = current_pomodoro_end_time + self.DELTA_LONG_BREAK_TIME
        else:
            next_stage = current_stage + 1
            current_break_end_time = current_pomodoro_end_time + self.DELTA_SHORT_BREAK_TIME

        next_pomodoro_end_time = current_break_end_time + self.DELTA_POMODORO_TIME

        # Pomodoro end notification: break start
        self.__scheduler.enterabs(
            current_pomodoro_end_time,
            self.DEFAULT_PRIORITY,
            self.__notify,
            kwargs=self.__pomodoro_end_notification(current_stage, current_break_end_time),
        )

        # Break end notification: next Pomodoro start
        self.__scheduler.enterabs(
            current_break_end_time,
            self.DEFAULT_PRIORITY,
            self.__notify,
            kwargs=self.__break_end_notification(next_stage, next_pomodoro_end_time),
        )

        self.__scheduler.run()

        if not self.__stop_scheduler:
            self.__log("Starting next Pomodoro...")
            self.__schedule_pomodoro(next_stage)

    def run(self):
        """Start Pomodoro timer."""
        try:
            self.__stop_scheduler = False
            current_time: float = self.__time_callable()
            current_time_str: str = time.strftime("%H:%M", time.localtime(current_time))
            self.__notify(
                "Pomodoro Timer",
                f"Current time {current_time_str}: Sarting Pomodoro in one minute...",
            )
            self.__log("Starting Pomodoro Timer.")
            next_stage: int = 1
            current_break_end_time: float = current_time + self.DELTA_START_TIME
            next_pomodoro_end_time: float = current_break_end_time + self.DELTA_POMODORO_TIME
            self.__scheduler.enterabs(
                current_break_end_time,
                self.DEFAULT_PRIORITY,
                self.__notify,
                kwargs=self.__break_end_notification(next_stage, next_pomodoro_end_time),
            )

            self.__scheduler.run()

            if not self.__stop_scheduler:
                self.__schedule_pomodoro(next_stage)
        except KeyboardInterrupt:
            self.stop()

    def stop(self):
        """Stop scheduler."""
        self.__log("Stopping the scheduler...")
        self.__stop_scheduler = True
        self.__notify("Stopping Pomodoro timer...")
        self.__clean_jobs()


def get_update_function(notifier: Notifier, logger: logging.Logger) -> Callable:
    """Obtain the notifier function given a notifier enum.

    :param notifier: The notifier to use.
    :returns: The notifier function.

    """
    if notifier == Notifier.DESKTOP:
        logger.info("Using desktop notifications.")
        return send_desktop_notification

    global TG_BOT_TOKEN, TG_MY_ID
    try:
        TG_BOT_TOKEN = environ["TG_BOT_TOKEN"]
        TG_MY_ID = environ["TG_MY_ID"]
    except KeyError:
        sys.exit("Ensure TG_BOT_TOKEN and TG_MY_ID variables are set.")

    if notifier == Notifier.TELEGRAM:
        logger.info("Using Telegram notifications.")
        return send_telegram_notification

    logger.info("Using all notifications.")
    return lambda t, b: list(
        map(
            lambda func: func(t, b),
            (send_telegram_notification, send_desktop_notification),
        )
    )


def main():
    """Main module entripoint."""
    logger: logging.Logger = logging.getLogger("PomodoroLogger")
    logger.setLevel(logging.DEBUG)
    stream_handler: logging.StreamHandler = logging.StreamHandler()
    stream_handler.setFormatter(
        logging.Formatter("{asctime}|{message}", style="{", datefmt="%Y%m%d-%H:%M")
    )
    logger.addHandler(stream_handler)
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        allow_abbrev=False,
    )
    parser.add_argument(
        "-n",
        "--notifier",
        action="store",
        choices=("telegram", "desktop", "all"),
        default="desktop",
    )
    args: argparse.Namespace = parser.parse_args()

    notifier = get_update_function(Notifier[args.notifier.upper()], logger)

    pom: PomodoroTimer = PomodoroTimer(notification_callable=notifier, logger=logger)
    logger.info("Starting Pomodoro timer.")
    pom.run()


if __name__ == "__main__":
    main()
