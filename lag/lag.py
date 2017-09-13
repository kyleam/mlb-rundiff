#!/usr/bin/python
"""Calculate time zone lag for each team in a game log

usage: calculate_lag.py [--with-ht] [FILE ...]
       calculate_lag.py [-h | --help]

FILE should be the name of an uncompressed retrosheet game log file
for a single year.  If FILE is not specified, stdin is consumed
instead.

arguments:

  --with-ht

      Calculate the lag values with the home team's time zone rather
      than the park's time zone.

      Do NOT use this.  It exists to make it easier to identify what
      discrepancies in lag values would arise in this case.
"""

from collections import namedtuple
from datetime import datetime

Game = namedtuple("Game",
                  ["date", "dbl_header",
                   "visiting_team", "visiting_gamenum",
                   "home_team", "home_gamenum",
                   "park"])


def parse_log(rows):
    """Parse retrosheet game log rows, yielding `lag.Game` namedtuples.
    """
    for row in rows:
        yield Game(date=datetime.strptime(row[0], "%Y%m%d"),
                   dbl_header=row[1],
                   visiting_team=row[3], visiting_gamenum=int(row[5]),
                   home_team=row[6], home_gamenum=int(row[8]),
                   park=row[16])


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

ZONES = {"ANA01": 3, "ARL01": 1, "ARL02": 1, "ATL01": 0, "ATL02": 0,
         "BAL11": 0, "BAL12": 0, "BOS07": 0, "CHI10": 1, "CHI11": 1,
         "CHI12": 1, "CIN08": 0, "CIN09": 0, "CLE07": 0, "CLE08": 0,
         "DEN01": 2, "DEN02": 2, "DET04": 0, "DET05": 0, "HON01": 6,
         "HOU02": 1, "HOU03": 1, "KAN06": 1, "LAS01": 3, "LBV01": 0,
         "LOS03": 3, "MIA01": 0, "MIA02": 0, "MIL05": 1, "MIL06": 1,
         "MIN03": 1, "MIN04": 1, "MNT01": 1, "MON02": 0, "NYC16": 0,
         "NYC17": 0, "NYC20": 0, "NYC21": 0, "OAK01": 3, "PHI12": 0,
         "PHI13": 0, "PHO01": 3, "PIT07": 0, "PIT08": 0, "SAN01": 3,
         "SAN02": 3, "SEA02": 3, "SEA03": 3, "SFO02": 3, "SFO03": 3,
         "SJU01": 0, "STL09": 1, "STL10": 1, "STP01": 0, "SYD01": 6,
         "TOK01": 6, "TOR02": 0, "WAS10": 0, "WAS11": 0}

_TEAM_ZONES = {"ANA": 3, "ARI": 3, "ATL": 0, "BAL": 0, "BOS": 0, "CAL": 3,
               "CHA": 1, "CHN": 1, "CIN": 0, "CLE": 0, "COL": 2, "DET": 0,
               "FLO": 0, "HOU": 1, "KCA": 1, "LAN": 3, "MIA": 0, "MIL": 1,
               "MIN": 1, "MON": 0, "NYA": 0, "NYN": 0, "OAK": 3, "PHI": 0,
               "PIT": 0, "SDN": 3, "SEA": 3, "SFN": 3, "SLN": 1, "TBA": 0,
               "TEX": 1, "TOR": 0, "WAS": 0}

TZ_LABEL = {0: "ET", 1: "CT", 2: "MT", 3: "PT", 6: "other"}

_HEADERS = ["date", "team", "game_tz", "lag", "matchup", "tz_shift",
            "days_delta", "dbl_header", "park"]


def park_to_zone(game):
    return ZONES[game.park]


def hometeam_to_zone(game):
    return _TEAM_ZONES[game.home_team]

Lag = namedtuple("Lag", ["date", "tz", "lag"])


def game_lags(games, zonefn = None):
    """Yield rolling lag for each team across games.

    Parameters
    ----------
    games : iterable
        An iterable that provides `lag.Game` namedtuples.
    zonefn : function
        A function that takes a `lag.Game` namedtuple and returns a
        time zone (integer).

    Returns
    -------
    An iterator the provides `lag.Lag` namedtuples (one for each team
    in each game).
    """
    team_lag = {}
    if zonefn is None:
        zonefn = park_to_zone

    for game in games:
        tz = zonefn(game)

        for team in game.home_team, game.visiting_team:
            if team in team_lag:
                state_prev = team_lag[team]
            else:
                state_prev = None
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

            fields = [game.date, team, TZ_LABEL[tz], lag,
                      # The remaining fields are unnecessary but
                      # useful for debugging.
                      "{}@{}".format(game.visiting_team, game.home_team),
                      "{}->{}".format(tz_prev, tz),
                      days_delta, game.dbl_header, game.park]

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
                     fields["dbl_header"],
                     fields["park"]])

if __name__ == '__main__':
    import csv
    import fileinput
    import sys

    from docopt import docopt
    args = docopt(__doc__)

    if args["--with-ht"]:
        zonefn = hometeam_to_zone
    else:
        zonefn = park_to_zone

    lines = csv.reader(fileinput.input(args["FILE"]))

    sys.stdout.write(",".join(_HEADERS) + "\n")
    for fields in game_lags(parse_log(lines), zonefn):
        try:
            sys.stdout.write(_format_output(fields) + "\n")
        except BrokenPipeError:
            sys.exit(0)
