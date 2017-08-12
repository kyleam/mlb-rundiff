#!/usr/bin/python
"""Calculate time zone lag for each team in a game log

usage: calculate_lag.py [FILE ...]
       calculate_lag.py [-h | --help]

FILE should be the name of an uncompressed retrolog file for a single
year.  If FILE is not specified, stdin is consumed instead.
"""

from collections import namedtuple
from datetime import datetime

Game = namedtuple("Game",
                  ["date", "dbl_header",
                   "visiting_team", "visiting_gamenum",
                   "home_team", "home_gamenum"])


def parse_log(rows):
    """Parse retrolog rows, yielding `lag.Game` namedtuples.
    """
    for row in rows:
        yield Game(date=datetime.strptime(row[0], "%Y%m%d"),
                   dbl_header=row[1],
                   visiting_team=row[3], visiting_gamenum=int(row[5]),
                   home_team=row[6], home_gamenum=int(row[8]))


def calculate_lag(lag_prev, days_delta, tz_prev, tz):
    """Calculate a new lag based on time zone move.

    Parameters
    ----------
    lag_prev : int
        Previous lag, with positive values representing west to east
        movement and negative values representing east to west.

    days_delta : int
        Days since previous game.  A double header is 0, a game on the
        following day is 1, and so on.

    tz_prev, tz : int
        Previous, new time zones.

    Returns
    -------
    An int representing the new lag.
    """
    lag_new = lag_prev + tz_prev - tz

    ndays = 0
    if tz_prev == tz:
        ndays = max(0, days_delta)
    else:
        ndays = max(0, days_delta - 1)

    if lag_new == 0 or ndays >= abs(lag_new):
        return 0
    elif lag_new > 0:
        return lag_new - ndays
    else:
        return lag_new + ndays

ZONES = {"ANA": 3, "ARI": 3, "ATL": 0, "BAL": 0, "BOS": 0, "CAL": 3,
         "CHA": 1, "CHN": 1, "CIN": 0, "CLE": 0, "COL": 2, "DET": 0,
         "FLO": 0, "HOU": 1, "KCA": 1, "LAN": 3, "MIA": 0, "MIL": 1,
         "MIN": 1, "MON": 0, "NYA": 0, "NYN": 0, "OAK": 3, "PHI": 0,
         "PIT": 0, "SDN": 3, "SEA": 3, "SFN": 3, "SLN": 1, "TBA": 0,
         "TEX": 1, "TOR": 0, "WAS": 0}

_HEADERS = ["date", "team", "game_tz", "lag", "matchup", "tz_shift",
            "days_delta", "dbl_header"]

Lag = namedtuple("Lag", ["date", "tz", "lag"])


def game_lags(games):
    """Yield rolling lag for each team across games.

    Parameters
    ----------
    games : iterable
        An iterable that provides `lag.Game` namedtuples.

    Returns
    -------
    An iterator the provides `lag.Lag` namedtuples (one for each team
    in each game).
    """
    tz_label = ["ET", "CT", "MT", "PT"]
    team_lag = {team: None for team in ZONES}

    for game in games:
        tz = ZONES[game.home_team]

        for team in game.home_team, game.visiting_team:
            state_prev = team_lag[team]
            tz_prev = None
            days_delta = 0
            if state_prev is None:
                tz_prev = tz
                lag = calculate_lag(0, days_delta, tz_prev, tz)
            else:
                tz_prev = state_prev.tz
                days_delta = (game.date - state_prev.date).days
                lag = calculate_lag(state_prev.lag, days_delta, tz_prev, tz)

                if game.date < state_prev.date:
                    raise ValueError("Logs are not sorted by date")

            fields = [game.date, team, tz_label[tz], lag,
                      # The remaining fields are unnecessary but
                      # useful for debugging.
                      "{}@{}".format(game.visiting_team, game.home_team),
                      "{}->{}".format(tz_prev, tz),
                      days_delta, game.dbl_header]

            yield dict(zip(_HEADERS, fields))

            team_lag[team] = Lag(game.date, tz, lag)


def _format_output(fields):
    return ",".join([fields["date"].strftime("%Y%m%d"),
                     fields["team"],
                     fields["game_tz"],
                     str(fields["lag"]),
                     # The remaining fields are unnecessary but useful
                     # for debugging.
                     fields["matchup"],
                     fields["tz_shift"],
                     str(fields["days_delta"]),
                     fields["dbl_header"]])

if __name__ == '__main__':
    import csv
    import fileinput
    import sys

    from docopt import docopt

    docopt(__doc__)
    lines = csv.reader(fileinput.input())

    sys.stdout.write(",".join(_HEADERS) + "\n")
    for fields in game_lags(parse_log(lines)):
        try:
            sys.stdout.write(_format_output(fields) + "\n")
        except BrokenPipeError:
            sys.exit(0)
