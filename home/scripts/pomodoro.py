#!/usr/bin/env python3
"""Pomodoro timer module.

When runing this python module you will start a pomodoro timer. Each 25 minutes
of work you will get 5 minutes break. At the end of the 4th Pomodoro you will
get a longer break (15 minutes).
"""
import sys
import time
import sched
import json
import logging
import urllib.request
import urllib.parse
import threading

from sched import Event
from urllib.error import HTTPError, URLError
from os import environ
from typing import Optional, Callable, Tuple, List


try:
    BOT_TOKEN = environ["BOT_TOKEN"]
    CHAT_ID = environ["CHAT_ID"]
except KeyError:
    sys.exit("Ensure BOT_TOKEN and CHAT_ID variables are set.")


def send_telegram_notification(title: str, body: str) -> None:
    """Send a telegram notification with the title and body provided.

    :param title: title of the notification.
    :param body: body of the notification.

    """
    print("Notifying:\n" f"- Title: {repr(title)}\n" f"- Body: {repr(body)}")
    bot_message = f"🍅 `{title}` 🍅\n_{body}_"
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


class PomodoroTimer(object):
    """Pomodoro timer."""

    DEFAULT_PRIORITY = 1
    DELTA_START_TIME = 1 * 60
    DELTA_POMODORO_TIME = 25 * 60
    DELTA_SHORT_BREAK_TIME = 5 * 60
    DELTA_LONG_BREAK_TIME = 15 * 60

    def __init__(
        self,
        notification_callable: Optional[Callable] = None,
        time_callable: Callable = time.time,
        sleep_callable: Callable = time.sleep,
        logger: Optional[logging.Logger] = None,
    ):
        """Pomodoro timer constructor.

        :param notification_callable: callable to send notifications with.
        :param time_callable: time-like function callable.
        :param sleep_callable: sleep-like function callable.
        :param logger: information logger.

        """
        self.__time_callable = time_callable
        self.__scheduler = sched.scheduler(time_callable, sleep_callable)
        self.__notification_callable = notification_callable or (
            lambda title, body: print(title, body, sep="\n")
        )
        self.__stop_scheduler = False
        self.__logger = logger

    def __log(self, message: str):
        """Log message if logger exists.

        :param message: message to log.

        """
        if self.__logger:
            self.__logger.debug(message)

    def __clean_jobs(self):
        """Clean remaining jobs."""
        while not self.__scheduler.empty():
            try:
                job = self.__scheduler.queue[0]
                self.__log(f"Cancelling job: {job}")
                self.__scheduler.cancel(job)
            except ValueError:
                pass
        else:
            self.__log("All jobs are finished.")

    def __pomodoro_end_notification(
        self, current_stage: int, current_break_end_time: float
    ) -> Tuple[str, str]:
        """Obtain the notification for the next Pomodoro start.

        :param current_stage: Current index of Pomodoro.
        :param current_break_end_time: Ending time of the break in seconds since epoch.
        """
        next_pomodoro_string = time.strftime(
            "%H:%M:%S", time.localtime(current_break_end_time)
        )

        return (
            f"Pomodoro[{current_stage}]::END",
            f"Next Pomodoro will start at {next_pomodoro_string}.",
        )

    def __break_end_notification(
        self, next_stage: int, next_pomodoro_end_time: float
    ) -> Tuple[str, str]:
        """Obtain the notification for the next break start.

        :param next_stage: Next index of Pomodoro.
        :param next_pomodoro_end_time: Ending time of the following Pomodoro in
            seconds since epoch.
        """
        next_break_string = time.strftime(
            "%H:%M:%S", time.localtime(next_pomodoro_end_time)
        )

        return (
            f"Pomodoro[{next_stage}]::START",
            f"Starting a new Pomodoro. 🔨 GO 🔨 TO 🔨 WORK 🔨\nNext break at "
            f"{next_break_string}.",
        )

    def __schedule_pomodoro(self, current_stage: int) -> None:
        """Schedule one Pomodoro and it's break time.

        If we are in the forth stage of Pomodoro, we will take a longer break.

        :param current_stage: Current Pomodoro stage.
        """
        current_time = self.__time_callable()
        current_pomodoro_end_time = current_time + self.DELTA_POMODORO_TIME

        if current_stage == 4:
            next_stage = 1
            current_break_end_time = (
                current_pomodoro_end_time + self.DELTA_LONG_BREAK_TIME
            )
        else:
            next_stage = current_stage + 1
            current_break_end_time = (
                current_pomodoro_end_time + self.DELTA_SHORT_BREAK_TIME
            )

        next_pomodoro_end_time = (
            current_break_end_time + self.DELTA_POMODORO_TIME
        )

        # Pomodoro end notification: break start
        self.__scheduler.enterabs(
            current_pomodoro_end_time,
            self.DEFAULT_PRIORITY,
            self.__notification_callable,
            argument=self.__pomodoro_end_notification(
                current_stage, current_break_end_time
            ),
        )

        # Break end notification: next Pomodoro start
        self.__scheduler.enterabs(
            current_break_end_time,
            self.DEFAULT_PRIORITY,
            self.__notification_callable,
            argument=self.__break_end_notification(
                next_stage, next_pomodoro_end_time
            ),
        )

        self.__scheduler.run()

        if not self.__stop_scheduler:
            self.__log("Starting next Pomodoro...")
            self.__schedule_pomodoro(next_stage)

    def run(self):
        """Start Pomodoro timer."""
        try:
            current_time = self.__time_callable()
            current_time_str = time.strftime(
                "%H:%M:%S", time.localtime(current_time)
            )
            self.__notification_callable(
                "Pomodoro Timer", f"Current time {current_time_str}: Sarting Pomodoro in one minute..."
            )
            self.__log("Starting Pomodoro Timer.")
            next_stage = 1
            current_break_end_time = (
                current_time + self.DELTA_START_TIME
            )
            next_pomodoro_end_time = (
                current_break_end_time + self.DELTA_POMODORO_TIME
            )
            self.__scheduler.enterabs(
                current_break_end_time,
                self.DEFAULT_PRIORITY,
                self.__notification_callable,
                argument=self.__break_end_notification(
                    next_stage, next_pomodoro_end_time
                ),
            )

            self.__scheduler.run()

            if not self.__stop_scheduler:
                self.__schedule_pomodoro(next_stage)
        except KeyboardInterrupt:
            self.__clean_jobs()

    def stop(self):
        """Stop scheduler."""
        self.__log("Stopping the scheduler...")
        self.__stop_scheduler = True
        self.__clean_jobs()


class PomodoroThread(threading.Thread):
    """Thread class with exception management."""

    def __init__(self, pomodoro):
        """Constructor."""
        super(PomodoroThread, self).__init__()
        self.__pomodoro_timer = pomodoro

    def run(self):
        """Run Pomodoro timer."""
        self.__pomodoro_timer.run()

    def stop_and_join(self):
        """Stop timer and wait until the thread ends."""
        self.__pomodoro_timer.stop()
        self.join()


def main(argv: List[str]):
    """Main module entripoint."""
    logger = logging.getLogger("PomodoroLogger")
    logger.setLevel(logging.DEBUG)
    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(
        logging.Formatter("{asctime}|{message}", style="{")
    )
    logger.addHandler(stream_handler)
    pom = PomodoroTimer(
        notification_callable=send_telegram_notification, logger=logger
    )

    if argv and argv[0] == "--thread":
        pomodoro_thread: PomodoroThread = PomodoroThread(pom)
        pomodoro_thread.start()
        try:
            pomodoro_thread.join()
        except KeyboardInterrupt:
            pomodoro_thread.stop_and_join()
    else:
        pom.run()


if __name__ == "__main__":
    main(sys.argv[1:])
