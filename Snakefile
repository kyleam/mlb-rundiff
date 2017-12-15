"""Snakemake build rules.

Here are some targets that might be of interest:

  * output/lag/log-with-lags-cleaned.csv

    Retrosheet game logs from 1990 through 2016 combined with the
    calculated lag values.

    See https://kyleam.github.io/mlb-rundiff/ and
    https://kyleam.github.io/mlb-rundiff/lag-calculation-checks.html
    for more information on these lag values.

    This should build quickly.

  * output/models/rundiff-oneseason_2011-fit.rds

    The Stan fit object for the code/models/rundiff-oneseason.stan ran
    on the 2011 season.

    See https://kyleam.github.io/mlb-rundiff/rundiff-oneseason-2011.html
    for a description of this simple "test" model.

    This shouldn't take more than a few minutes to run.

  * output/models/rundiff-lagwe_1992-2011-fit.rds

    The Stan fit object for the code/models/rundiff-lagwe.stan model
    ran on the 1992 through 2011 data set.

    See https://kyleam.github.io/mlb-rundiff/ for a description of the
    model.

    This could take a while -- think overnight.

  * site/index.html

    Build the https://kyleam.github.io/mlb-rundiff/ site locally.

    This could take a while -- think overnight.

Run `snakemake --list` or `snakemake --list-target-rules` to see a
list of all available rules.
"""

from glob import glob

RSCRIPT="Rscript --no-save --no-restore --no-site-file --no-init-file "


rule help:
    run:
        print(__doc__)


### Data download

rule gamelogs_download_column_info:
    output: "gamelogs/glfields.txt"
    shell: "cd gamelogs && "
           "wget http://www.retrosheet.org/gamelogs/glfields.txt"

rule gamelogs_download_park_codes:
    output: "gamelogs/parkcode.txt"
    shell: "cd gamelogs && "
           "wget http://www.retrosheet.org/parkcode.txt"

rule gamelogs_cut_park_codes:
    input: "gamelogs/parkcode.txt"
    output: "gamelogs/parkcode-cut.csv"
    shell: "sed 1d {input} | cut -f1,2 -d, > {output}"

rule gamelogs_download_person_id:
    output: "gamelogs/retroID.htm"
    shell: "cd gamelogs && "
           "wget http://www.retrosheet.org/retroID.htm"

rule gamelogs_extract_person_id:
    input: "gamelogs/retroID.htm",
    output: "gamelogs/person-ids.csv"
    shell:  "echo 'last,first,id,debut' > {output} &&"
            "awk 'f;/LAST,FIRST/{{f=1}}' {input} | "
            "awk '/^$/ {{exit}} {{print}}' >> {output}"

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
    output: "gamelogs/{year,[0-9]+}.csv"
    shell: "dos2unix -n {input} {output}"

rule gamelogs_combine_years:
    input: expand("gamelogs/{year}.csv", year=range(1990, 2016))
    output: "gamelogs/1990_2016.csv"
    shell: "cat {input} > {output}"

rule gamelogs_pythagorean:
    input: "gamelogs/pythagorean.R",
           "gamelogs/1990_2016.csv",
           "gamelogs/game-log-header.txt"
    output: "gamelogs/wins-pythagorean.csv"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "./$(basename {input[0]})"


### Calculation of lag

rule lag_spread_incomplete_:
    input: "lag/spread_incomplete.py", "gamelogs/{year}.csv"
    output: "gamelogs/{year}-spread.csv"
    shell: "python3 {input[0]} {input[1]} | sort -t, -k1,1 > {output}"

rule lag_calculate_:
    input: "lag/lag.py", "gamelogs/{year}-spread.csv"
    output: "lag/{year}.csv"
    shell: "python3 {input[0]} {input[1]} > {output}"

rule lag_calculate_with_ht_:
    input: "lag/lag.py", "gamelogs/{year}-spread.csv"
    output: "lag/{year}-ht.csv"
    shell: "python3 {input[0]} --with-ht {input[1]} > {output}"

rule lag_combine_:
    input: expand("lag/{year}{{kind}}.csv", year=range(1990, 2016))
    output: "lag/lag-combined-1990_2016{kind,(|-ht)}.csv"
    shell: "head -n1  {input[0]} > {output} &&"
           "for f in {input}; do sed 1d $f >> {output}; done"

rule lag_sort_combined:
    input: "lag/sort-combined.R", "lag/lag-combined-1990_2016.csv"
    output: "lag/lag-combined-sorted-1990_2016.csv"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "./$(basename {input[0]})"

rule lag_join_log_and_lag:
    input: "lag/join-log-and-lag.R",
           "lag/lag-combined-1990_2016.csv",
           "gamelogs/game-log-header.txt",
           "gamelogs/1990_2016.csv"
    output: "lag/log-with-lags.csv"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "./$(basename {input[0]})"

rule lag_clean_log_with_lags:
    input: "lag/clean-log-with-lags.R",
           "lag/log-with-lags.csv"
    output: "lag/log-with-lags-cleaned.csv"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "./$(basename {input[0]})"

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


### Models

rule models_dump_rundiff_oneseason_2011_data:
    input: "models/dump-rundiff-oneseason_2011-data.R",
           "lag/log-with-lags-cleaned.csv"
    output: "models/rundiff-oneseason_2011.data.R",
            "models/rundiff-oneseason_2011.info.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_dump_rundiff_split_2011_data:
    input: "models/dump-rundiff-split_2011-data.R",
           "lib/utils.R",
           "lag/log-with-lags-cleaned.csv"
    output: "models/rundiff-split_2011.data.R",
            "models/rundiff-split_2011.info.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_dump_rundiff_pitch_2011_data:
    input: "models/dump-rundiff-pitch_2011-data.R",
           "lib/utils.R",
           "lag/log-with-lags-cleaned.csv"
    output: "models/rundiff-pitch_2011.data.R",
            "models/rundiff-pitch_2011.info.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_dump_rundiff_park_2011_data:
    input: "models/dump-rundiff-park_2011-data.R",
           "lib/utils.R",
           "lag/log-with-lags-cleaned.csv"
    output: "models/rundiff-park_2011.data.R",
            "models/rundiff-park_2011.info.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_dump_rundiff_year_range_data_:
    input: "models/dump-rundiff-{name}-data-year-range.R",
           "lib/utils.R",
           "lag/log-with-lags-cleaned.csv"
    output: "models/rundiff-{name}_{year1}-{year2}.data.R",
            "models/rundiff-{name}_{year1}-{year2}.info.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]}) "
           "{wildcards.year1} {wildcards.year2}"

rule models_dump_rundiff_home_1992_2011_data:
    input: "models/dump-rundiff-home_1992-2011-data.R",
           "lag/log-with-lags-cleaned.csv"
    output: "models/rundiff-home_1992-2011.data.R",
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_sample_:
    input: "models/sample-{model}_{data}.R",
           "models/{model}.stan",
           "models/{model}_{data}.data.R"
    output: protected("models/{model}_{data}-fit.rds")
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_sim_rundiff_lagwe_1992_2011:
    input: "models/sim-rundiff-lagwe_1992-2011.R",
           "models/sim-rundiff-lagwe.R",
           "models/rundiff-lagwe_1992-2011-fit.rds",
           "models/rundiff-lagwe_1992-2011.info.R",
           "models/rundiff-lagwe_1992-2011.data.R"
    output: protected("models/rundiff-lagwe_1992-2011-sim.rds")
    shell: "cd $(dirname {input[0]}) && "
           "time " + RSCRIPT + "$(basename {input[0]})"

rule models_sim_cov_rundiff_lagwe_1992_2011:
    input: "models/sim-cov-rundiff-lagwe_1992-2011.R",
           "models/rundiff-lagwe_1992-2011-sim.rds",
           "models/rundiff-lagwe_1992-2011.data.R"
    output: "models/rundiff-lagwe_1992-2011-sim-cov.dat"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]}) > $(basename {output})"

rule models_sim_wins_rundiff_lagwe_1992_2011:
    input: "models/sim-wins-rundiff-lagwe_1992-2011.R",
           "models/rundiff-lagwe_1992-2011-sim.rds",
           "models/rundiff-lagwe_1992-2011.data.R",
           "models/rundiff-lagwe_1992-2011.info.R"
    output: "models/rundiff-lagwe_1992-2011-sim-wins.rds"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_sim_rgames_rundiff_lagwe_1992_2011:
    input: "models/sim-rgames-rundiff-lagwe_1992-2011.R",
           "models/rundiff-lagwe_1992-2011-sim.rds",
           "models/rundiff-lagwe_1992-2011.data.R",
           "models/rundiff-lagwe_1992-2011.info.R"
    output: "models/rundiff-lagwe_1992-2011-sim-rgames.rds"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_sim_rundiff_home_1992_2011_data:
    input: "models/sim-rundiff-home_1992-2011-data.R",
    output: "models/rundiff-home_1992-2011-sim.data.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"


### Rmarkdown

rmd_site_input = [
    "gamelogs/parkcode-cut.csv",
    "gamelogs/person-ids.csv",
    "gamelogs/wins-pythagorean.csv",
    "lag/2011.csv",
    "lag/lag-combined-1990_2016-ht.csv",
    "lag/lag-combined-1990_2016.csv",
    "lag/log-with-lags-cleaned.csv",
    "lag/song2017how-table-s2.csv",
    "lib/utils.R",
    "models/rundiff-home_1992-2011-fit.rds",
    "models/rundiff-lagwe_1992-2011-fit.rds",
    "models/rundiff-lagwe_1992-2011-sim-cov.dat",
    "models/rundiff-lagwe_1992-2011-sim-rgames.rds",
    "models/rundiff-lagwe_1992-2011-sim-wins.rds",
    "models/rundiff-lagwe_1992-2011.data.R",
    "models/rundiff-lagwe_1992-2011.info.R",
    "models/rundiff-oneseason.stan",
    "models/rundiff-oneseason_2011-fit.rds",
    "models/rundiff-split_2011-fit.rds",
    "models/rundiff-split_2011.data.R",
    "models/rundiff-split_2011.info.R",
    "rmd/_site.yml",
    "rmd/_song2017how-table-s1.md",
    "rmd/footer.html",
    "rmd/plot-utils.R",
    "rmd/rundiff-split.stan",
    "rmd/setup.R",
    "rmd/styles.css",
]

rule rmd_copy_rundiff_split_model:
    input: "models/rundiff-split.stan"
    output: "rmd/rundiff-split.stan"
    shell: "cp {input} {output}"

rule rmd_render_site:
    input: rmd_site_input, glob("rmd/*.Rmd"), glob("rmd/*.md")
    output: "site/index.html"
    shell: "cd rmd && " + RSCRIPT + "--slave -e "
           "'require(rmarkdown); rmarkdown::render_site()'"
