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


### Initial data processing

rule gamelogs_cut_park_codes:
    input: "input/gamelogs/parkcode.txt"
    output: "output/parkcode-cut.csv"
    shell: "sed 1d {input} | cut -f1,2 -d, > {output}"

rule gamelogs_extract_person_id:
    input: "input/gamelogs/retroID.htm",
    output: "output/person-ids.csv"
    shell:  "echo 'last,first,id,debut' > {output} &&"
            "awk 'f;/LAST,FIRST/{{f=1}}' {input} | "
            "awk '/^$/ {{exit}} {{print}}' >> {output}"

rule gamelogs_convert_and_rename_:
    input: "input/gamelogs/GL{year}.TXT"
    output: "output/gamelogs/{year,[0-9]+}.csv"
    shell: "dos2unix -n {input} {output}"

rule gamelogs_combine_years:
    input: expand("output/gamelogs/{year}.csv", year=range(1990, 2016))
    output: "output/gamelogs-1990_2016.csv"
    shell: "cat {input} > {output}"

rule gamelogs_pythagorean:
    input: "code/pythagorean.R",
           "output/gamelogs-1990_2016.csv",
           "input/game-log-header.txt"
    output: "output/wins-pythagorean.csv"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "./$(basename {input[0]})"


### Calculation of lag

rule lag_spread_incomplete_:
    input: "code/lag/spread_incomplete.py", "output/gamelogs/{year}.csv"
    output: "output/gamelogs/{year}-spread.csv"
    shell: "python3 {input[0]} {input[1]} | sort -t, -k1,1 > {output}"

rule lag_calculate_:
    input: "code/lag/lag.py", "output/gamelogs/{year}-spread.csv"
    output: "output/lag/{year}.csv"
    shell: "python3 {input[0]} {input[1]} > {output}"

rule lag_calculate_with_ht_:
    input: "code/lag/lag.py", "output/gamelogs/{year}-spread.csv"
    output: "output/lag/{year}-ht.csv"
    shell: "python3 {input[0]} --with-ht {input[1]} > {output}"

rule lag_combine_:
    input: expand("output/lag/{year}{{kind}}.csv", year=range(1990, 2016))
    output: "output/lag/lag-combined-1990_2016{kind,(|-ht)}.csv"
    shell: "head -n1  {input[0]} > {output} &&"
           "for f in {input}; do sed 1d $f >> {output}; done"

rule lag_sort_combined:
    input: "code/lag/sort-combined.R", "output/lag/lag-combined-1990_2016.csv"
    output: "output/lag/lag-combined-sorted-1990_2016.csv"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "./$(basename {input[0]})"

rule lag_join_log_and_lag:
    input: "code/lag/join-log-and-lag.R",
           "output/lag/lag-combined-1990_2016.csv",
           "input/game-log-header.txt",
           "output/gamelogs-1990_2016.csv"
    output: "output/lag/log-with-lags.csv"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "./$(basename {input[0]})"

rule lag_clean_log_with_lags:
    input: "code/lag/clean-log-with-lags.R",
           "output/lag/log-with-lags.csv"
    output: "output/lag/log-with-lags-cleaned.csv"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "./$(basename {input[0]})"

rule lag_download_song2017how_supp_table_:
    output: "input/lag/pnas.1608847114.st{id,(01|02)}.docx"
    shell: "cd input/lag && "
           "wget http://www.pnas.org/content/suppl/2017/01/18/"
           "1608847114.DCSupplemental/pnas.1608847114.st{wildcards.id}.docx"

rule lag_convert_song2017how_table_s1_to_md:
    input: "input/lag/pnas.1608847114.st01.docx"
    output: "docs/_song2017how-table-s1.md"
    shell: "pandoc -f docx -t markdown {input} |"
           "sed 's/West    /**West**/' | sed 's/East    /**East**/' | "
           "awk '/^$/ {{exit}} {{print}}' > {output}"

rule lag_convert_song2017how_table_s2_to_text:
    input: "input/lag/pnas.1608847114.st02.docx"
    output: temp("output/lag/song2017how-table-s2.dat")
    shell: "pandoc -f docx -t plain {input} > {output}"

rule lag_convert_song2017how_table_s2_to_csv:
    input: "output/lag/song2017how-table-s2.dat"
    output: "output/lag/song2017how-table-s2.csv"
    shell: "printf 'date,away,home,away_lag,home_lag\n' > {output}.tmp && "
           "awk '/^ +[0-9]/ {{print}}' {input} | "
           "sed 's/^ \+//g' | sed 's/ \+/,/g' >> {output}.tmp && "
           "mv {output}.tmp {output}"


### Models

rule models_dump_rundiff_oneseason_2011_data:
    input: "code/models/dump-rundiff-oneseason_2011-data.R",
           "output/lag/log-with-lags-cleaned.csv"
    output: "output/models/rundiff-oneseason_2011.data.R",
            "output/models/rundiff-oneseason_2011.info.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_dump_rundiff_split_2011_data:
    input: "code/models/dump-rundiff-split_2011-data.R",
           "code/lib/utils.R",
           "output/lag/log-with-lags-cleaned.csv"
    output: "output/models/rundiff-split_2011.data.R",
            "output/models/rundiff-split_2011.info.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_dump_rundiff_pitch_2011_data:
    input: "code/models/dump-rundiff-pitch_2011-data.R",
           "code/lib/utils.R",
           "output/lag/log-with-lags-cleaned.csv"
    output: "output/models/rundiff-pitch_2011.data.R",
            "output/models/rundiff-pitch_2011.info.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_dump_rundiff_park_2011_data:
    input: "code/models/dump-rundiff-park_2011-data.R",
           "code/lib/utils.R",
           "output/lag/log-with-lags-cleaned.csv"
    output: "output/models/rundiff-park_2011.data.R",
            "output/models/rundiff-park_2011.info.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_dump_rundiff_year_range_data_:
    input: "code/models/dump-rundiff-{name}-data-year-range.R",
           "code/lib/utils.R",
           "output/lag/log-with-lags-cleaned.csv"
    output: "output/models/rundiff-{name}_{year1}-{year2}.data.R",
            "output/models/rundiff-{name}_{year1}-{year2}.info.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]}) "
           "{wildcards.year1} {wildcards.year2}"

rule models_dump_rundiff_home_1992_2011_data:
    input: "code/models/dump-rundiff-home_1992-2011-data.R",
           "output/lag/log-with-lags-cleaned.csv"
    output: "output/models/rundiff-home_1992-2011.data.R",
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_sample_:
    input: "code/models/sample-{model}_{data}.R",
           "code/models/{model}.stan",
           "output/models/{model}_{data}.data.R"
    output: protected("output/models/{model}_{data}-fit.rds")
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_sim_rundiff_lagwe_1992_2011:
    input: "code/models/sim-rundiff-lagwe_1992-2011.R",
           "code/models/sim-rundiff-lagwe.R",
           "output/models/rundiff-lagwe_1992-2011-fit.rds",
           "output/models/rundiff-lagwe_1992-2011.info.R",
           "output/models/rundiff-lagwe_1992-2011.data.R"
    output: protected("output/models/rundiff-lagwe_1992-2011-sim.rds")
    shell: "cd $(dirname {input[0]}) && "
           "time " + RSCRIPT + "$(basename {input[0]})"

rule models_sim_cov_rundiff_lagwe_1992_2011:
    input: "code/models/sim-cov-rundiff-lagwe_1992-2011.R",
           "output/models/rundiff-lagwe_1992-2011-sim.rds",
           "output/models/rundiff-lagwe_1992-2011.data.R"
    output: "output/models/rundiff-lagwe_1992-2011-sim-cov.dat"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]}) > $(basename {output})"

rule models_sim_wins_rundiff_lagwe_1992_2011:
    input: "code/models/sim-wins-rundiff-lagwe_1992-2011.R",
           "output/models/rundiff-lagwe_1992-2011-sim.rds",
           "output/models/rundiff-lagwe_1992-2011.data.R",
           "output/models/rundiff-lagwe_1992-2011.info.R"
    output: "output/models/rundiff-lagwe_1992-2011-sim-wins.rds"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_sim_rgames_rundiff_lagwe_1992_2011:
    input: "code/models/sim-rgames-rundiff-lagwe_1992-2011.R",
           "output/models/rundiff-lagwe_1992-2011-sim.rds",
           "output/models/rundiff-lagwe_1992-2011.data.R",
           "output/models/rundiff-lagwe_1992-2011.info.R"
    output: "output/models/rundiff-lagwe_1992-2011-sim-rgames.rds"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_sim_rundiff_home_1992_2011_data:
    input: "code/models/sim-rundiff-home_1992-2011-data.R",
    output: "output/models/rundiff-home_1992-2011-sim.data.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"


### Rmarkdown

docs_site_input = [
    "code/lib/utils.R",
    "code/models/rundiff-oneseason.stan",
    "docs/_site.yml",
    "docs/_song2017how-table-s1.md",
    "docs/footer.html",
    "docs/plot-utils.R",
    "docs/rundiff-split.stan",
    "docs/setup.R",
    "docs/styles.css",
    "output/lag/2011.csv",
    "output/lag/lag-combined-1990_2016-ht.csv",
    "output/lag/lag-combined-1990_2016.csv",
    "output/lag/log-with-lags-cleaned.csv",
    "output/lag/song2017how-table-s2.csv",
    "output/models/rundiff-home_1992-2011-fit.rds",
    "output/models/rundiff-lagwe_1992-2011-fit.rds",
    "output/models/rundiff-lagwe_1992-2011-sim-cov.dat",
    "output/models/rundiff-lagwe_1992-2011-sim-rgames.rds",
    "output/models/rundiff-lagwe_1992-2011-sim-wins.rds",
    "output/models/rundiff-lagwe_1992-2011.data.R",
    "output/models/rundiff-lagwe_1992-2011.info.R",
    "output/models/rundiff-oneseason_2011-fit.rds",
    "output/models/rundiff-split_2011-fit.rds",
    "output/models/rundiff-split_2011.data.R",
    "output/models/rundiff-split_2011.info.R",
    "output/parkcode-cut.csv",
    "output/person-ids.csv",
    "output/wins-pythagorean.csv",
]

rule docs_copy_rundiff_split_model:
    input: "code/models/rundiff-split.stan"
    output: "docs/rundiff-split.stan"
    shell: "cp {input} {output}"

rule docs_render_site:
    input: docs_site_input, glob("docs/*.Rmd"), glob("docs/*.md")
    output: "site/index.html"
    shell: "cd docs && " + RSCRIPT + "--slave -e "
           "'require(rmarkdown); rmarkdown::render_site()'"
