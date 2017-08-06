
rule download_column_info:
    output: "data/glfields.txt"
    shell: "cd data && wget http://www.retrosheet.org/gamelogs/glfields.txt"
