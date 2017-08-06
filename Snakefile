
rule download_column_info:
    output: "data/glfields.txt"
    shell: "cd data && wget http://www.retrosheet.org/gamelogs/glfields.txt"

rule download_column_header:
    output: "data/game_log_header.csv"
    shell: "cd data && "
           "wget https://raw.githubusercontent.com/"
           "maxtoki/baseball_R/master/data/game_log_header.csv"
