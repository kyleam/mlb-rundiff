from glob import glob


### Data download

rule gamelogs_download_column_info:
    output: "gamelogs/glfields.txt"
    shell: "cd gamelogs && "
           "wget http://www.retrosheet.org/gamelogs/glfields.txt"

rule gamelogs_download_column_header:
    output: "gamelogs/game_log_header.csv"
    shell: "cd gamelogs && "
           "wget https://raw.githubusercontent.com/"
           "maxtoki/baseball_R/master/data/game_log_header.csv"

rule gamelogs_download_:
    output: "gamelogs/{name}.zip"
    shell: "cd gamelogs && "
           "wget http://www.retrosheet.org/gamelogs/{wildcards.name}.zip"

rule gamelogs_unzip_gl1990_99:
    input: "gamelogs/gl1990_99.zip"
    output: temp(["gamelogs/GL{}.TXT".format(year) for year in range(1990, 2000)])
    shell: "cd $(dirname {input[0]}) && unzip $(basename {input[0]})"

rule gamelogs_unzip_gl2000_09:
    input: "gamelogs/gl2000_09.zip"
    output: temp(["gamelogs/GL{}.TXT".format(year) for year in range(2000, 2010)])
    shell: "cd $(dirname {input[0]}) && unzip $(basename {input[0]})"

rule gamelogs_unzip_gl2010_16:
    input: "gamelogs/gl2010_16.zip"
    output: temp(["gamelogs/GL{}.TXT".format(year) for year in range(2010, 2017)])
    shell: "cd $(dirname {input[0]}) && unzip $(basename {input[0]})"

rule gamelogs_convert_and_rename_:
    input: "gamelogs/GL{year}.TXT"
    output: "gamelogs/{year}.csv"
    shell: "dos2unix -n {input} {output}"

rule gamelogs_combine_years:
    input: expand("gamelogs/{year}.csv", year=range(1992, 2012))
    output: "gamelogs/1992_2011.csv"
    shell: "cat {input} > {output}"


### Calculation of lag

rule lag_calculate:
    input: "lag/lag.py", "gamelogs/{year}.csv"
    output: "lag/{year}.csv"
    shell: "python {input[0]} {input[1]} > {output}"

rule lag_combine:
    input: expand("lag/{year}.csv", year=range(1992, 2012))
    output: "lag/lag-combined-1992_2011.csv"
    shell: "head -n1  {input[0]} > {output} &&"
           "for f in {input}; do sed 1d $f >> {output}; done"

rule lag_sort_combined:
    input: "lag/sort-combined.R", "lag/lag-combined-1992_2011.csv"
    output: "lag/lag-combined-sorted-1992_2011.csv"
    shell: "cd $(dirname {input[0]}) && "
           "Rscript --vanilla ./$(basename {input[0]})"

rule lag_thanks_u2:
    input: "lag/thanks-u2.R", "lag/lag-combined-sorted-1992_2011.csv"
    output: "lag/lag-combined-u2-1992_2011.csv"
    shell: "cd $(dirname {input[0]}) && "
           "Rscript --vanilla ./$(basename {input[0]})"

rule lag_join_log_and_lag:
    input: "lag/join-log-and-lag.R",
           "lag/lag-combined-u2-1992_2011.csv",
           "gamelogs/game_log_header.csv",
           "gamelogs/1992_2011.csv"
    output: "lag/log-with-lags.csv"
    shell: "cd $(dirname {input[0]}) && "
           "Rscript --vanilla ./$(basename {input[0]})"

rule lag_clean_log_with_lags:
    input: "lag/clean-log-with-lags.R",
           "lag/log-with-lags.csv"
    output: "lag/log-with-lags-cleaned.csv"
    shell: "cd $(dirname {input[0]}) && "
           "Rscript --vanilla ./$(basename {input[0]})"

rule lag_download_song2017how_supp_table_:
    output: "lag/pnas.1608847114.st{id,(01|02)}.docx"
    shell: "cd lag && "
           "wget http://www.pnas.org/content/suppl/2017/01/18/"
           "1608847114.DCSupplemental/pnas.1608847114.st{wildcards.id}.docx"

rule lag_convert_song2017how_table_s1_to_md:
    input: "lag/pnas.1608847114.st01.docx"
    output: "rmd/_song2017how-table-s1.md"
    shell: "pandoc -f docx -t markdown {input} |"
           "sed 's/West    /**West**/' | sed 's/East    /**East**/' | "
           "awk '/^$/ {{exit}} {{print}}' > {output}"

rule lag_convert_song2017how_table_s2_to_text:
    input: "lag/pnas.1608847114.st02.docx"
    output: temp("lag/song2017how-table-s2.dat")
    shell: "pandoc -f docx -t plain {input} > {output}"

rule lag_convert_song2017how_table_s2_to_csv:
    input: "lag/song2017how-table-s2.dat"
    output: "lag/song2017how-table-s2.csv"
    shell: "printf 'date,away,home,away_lag,home_lag\n' > {output}.tmp && "
           "awk '/^ +[0-9]/ {{print}}' {input} | "
           "sed 's/^ \+//g' | sed 's/ \+/,/g' >> {output}.tmp && "
           "mv {output}.tmp {output}"


### Rmarkdown

rmd_site_input = [
    "lag/2011.csv",
    "lag/lag-combined-1992_2011.csv",
    "lag/song2017how-table-s2.csv",
    "rmd/_song2017how-table-s1.md",
]

rule rmd_render_site:
    input: "rmd/_site.yml", "rmd/styles.css", "rmd/setup.R",
           rmd_site_input, glob("rmd/*.Rmd"), glob("rmd/*.md")
    output: "site/index.html"
    shell: "cd rmd && "
           "Rscript --vanilla --slave -e "
           "'require(rmarkdown); rmarkdown::render_site()'"
