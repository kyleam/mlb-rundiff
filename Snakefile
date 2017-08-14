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


### Rmarkdown

rmd_site_input = []

rule rmd_render_site:
    input: "rmd/_site.yml", "rmd/styles.css", "rmd/setup.R",
           rmd_site_input, glob("rmd/*.Rmd"), glob("rmd/*.md")
    output: "site/index.html"
    shell: "cd rmd && "
           "Rscript --vanilla --slave -e "
           "'require(rmarkdown); rmarkdown::render_site()'"
