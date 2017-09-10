import pytest
import lag

from datetime import datetime
import itertools

tzs = list(range(0, 4))

# rows = from, columns = to
#
#           ET  CT  MT  PT
tz_same = [[ 0,  0, -1, -2],
           [ 0,  0,  0, -1],
           [ 1,  0,  0,  0],
           [ 2,  1,  0,  0]]

tz_diff = [[ 0, -1, -2, -3],
           [ 1,  0, -1, -2],
           [ 2,  1,  0, -1],
           [ 3,  2,  1,  0]]

@pytest.mark.parametrize("tz_prev", tzs)
@pytest.mark.parametrize("tz", tzs)
def test_calculate_lag__vary_tzs(tz_prev, tz):
    result = lag.calculate_lag(0, 1, tz_prev, tz)
    if tz_prev == tz:
        assert result == tz_same[tz_prev][tz]
    else:
        assert result == tz_diff[tz_prev][tz]

def test_calculate_lag__vary_lag_prev():
    # ET -> PT
    assert lag.calculate_lag(0, 1, 0, 3) == -3
    assert lag.calculate_lag(1, 1, 0, 3) == -2
    assert lag.calculate_lag(-1, 1, 0, 3) == -4

    # PT -> CT
    assert lag.calculate_lag(0, 1, 3, 1) == 2
    assert lag.calculate_lag(1, 1, 3, 1) == 3
    assert lag.calculate_lag(-1, 1, 3, 1) == 1

    # Unrealistic values are accepted for the previous lag.
    assert lag.calculate_lag(100, 1, 0, 3) == 97
    assert lag.calculate_lag(-100, 1, 0, 3) == -103
    assert lag.calculate_lag(100, 1, 3, 1) == 102
    assert lag.calculate_lag(-100, 1, 3, 1) == -98

def test_calculate_lag__vary_days_delta():
    assert lag.calculate_lag(3, 3, 0, 0) == 0
    assert lag.calculate_lag(3, 2, 0, 0) == 1
    assert lag.calculate_lag(-3, 2, 0, 0) == -1

    assert lag.calculate_lag(0, 3, 1, 1) == 0
    assert lag.calculate_lag(2, 5, 1, 1) == 0

    # Ignore days_delta of 0 or 1 when there is a timezone change.
    assert lag.calculate_lag(0, 0, 0, 3) == -3
    assert lag.calculate_lag(0, 0, 3, 1) == 2
    assert lag.calculate_lag(0, 1, 0, 3) == -3
    assert lag.calculate_lag(0, 1, 3, 1) == 2
    # Adjust lag for days off.
    assert lag.calculate_lag(0, 2, 0, 3) == -2
    assert lag.calculate_lag(0, 2, 3, 1) == 1

def test_game_lags():
    games = [lag.Game(date=datetime.strptime("20000405", "%Y%m%d"),
                      dbl_header="0",
                      visiting_team="SEA",
                      visiting_gamenum=1,
                      home_team="NYA",
                      home_gamenum=1,
                      park="NYC16"),
             lag.Game(date=datetime.strptime("20000405", "%Y%m%d"),
                      dbl_header="0",
                      visiting_team="COL",
                      visiting_gamenum=1,
                      home_team="LAN",
                      home_gamenum=1,
                      park = "LOS03"),
             lag.Game(date=datetime.strptime("20000406", "%Y%m%d"),
                      dbl_header="1",
                      ## Home and away are swapped with park.
                      visiting_team="CIN",
                      visiting_gamenum=1,
                      home_team="COL",
                      home_gamenum=2,
                      park="CIN08"),
             lag.Game(date=datetime.strptime("20000406", "%Y%m%d"),
                      dbl_header="2",
                      visiting_team="COL",
                      visiting_gamenum=3,
                      home_team="CIN",
                      home_gamenum=2,
                      park="CIN08"),
             lag.Game(date=datetime.strptime("20000406", "%Y%m%d"),
                      dbl_header="0",
                      visiting_team="SLN",
                      visiting_gamenum=1,
                      home_team="SEA",
                      home_gamenum=2,
                      park="SEA03"),
             lag.Game(date=datetime.strptime("20000407", "%Y%m%d"),
                      dbl_header="0",
                      visiting_team="COL",
                      visiting_gamenum=4,
                      home_team="CIN",
                      home_gamenum=3,
                      park="CIN08"),
             lag.Game(date=datetime.strptime("20000412", "%Y%m%d"),
                      dbl_header="0",
                      visiting_team="NYA",
                      visiting_gamenum=2,
                      home_team="SEA",
                      home_gamenum=3,
                      park="SEA03")]

    result = list(lag.game_lags(games))

    assert len(result) == 2 * len(games)

    # Everyone starts out with no lag.
    for idx in range(0, 4):
        assert result[idx]["lag"] == 0

    # COL came from LAN to CIN (but played game as home team).
    assert result[4]["lag"] == 3
    assert result[5]["lag"] == 0
    # Second game of double header should match the first.
    assert result[6]["lag"] == 0
    assert result[7]["lag"] == 3
    # Lag goes down the day after the double header.
    assert result[11]["lag"] == 2

    # SEA came home from NYA.
    assert result[8]["lag"] == -3

    # Next game for SEA happens after 5 day rest.
    assert result[12]["lag"] == 0
    # NYA came from home to SEA, but last game was 5 days ago.
    assert result[13]["lag"] == 0
