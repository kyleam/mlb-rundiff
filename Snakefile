
rule download_column_info:
    output: "data/glfields.txt"
    shell: "cd data && wget http://www.retrosheet.org/gamelogs/glfields.txt"

rule download_column_header:
    output: "data/game_log_header.csv"
    shell: "cd data && "
           "wget https://raw.githubusercontent.com/"
           "maxtoki/baseball_R/master/data/game_log_header.csv"

rule download_:
    output: "data/{name}.zip"
    shell: "cd data && "
           "wget http://www.retrosheet.org/gamelogs/{wildcards.name}.zip"

rule unzip_gl1990_99:
    input: "data/gl1990_99.zip"
    output: temp(["data/GL{}.TXT".format(year) for year in range(1990, 2000)])
    shell: "cd $(dirname {input[0]}) && unzip $(basename {input[0]})"

rule unzip_gl2000_09:
    input: "data/gl2000_09.zip"
    output: temp(["data/GL{}.TXT".format(year) for year in range(2000, 2010)])
    shell: "cd $(dirname {input[0]}) && unzip $(basename {input[0]})"

rule unzip_gl2010_16:
    input: "data/gl2010_16.zip"
    output: temp(["data/GL{}.TXT".format(year) for year in range(2010, 2017)])
    shell: "cd $(dirname {input[0]}) && unzip $(basename {input[0]})"

rule convert_and_rename_log_:
    input: "data/GL{year}.TXT"
    output: "data/game-log-{year}.txt"
    shell: "dos2unix -n {input} {output}"
