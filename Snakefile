"""Snakemake build rules.

Here are some targets that might be of interest:

  * outputs/lag/log-with-lags-cleaned.csv

    Retrosheet game logs from 1990 through 2016 combined with the
    calculated lag values.

    See https://kyleam.github.io/mlb-rundiff/ and
    https://kyleam.github.io/mlb-rundiff/lag-calculation-checks.html
    for more information on these lag values.

    This should build quickly.

  * outputs/models/rundiff-oneseason_2011-fit.rds

    The Stan fit object for the code/models/rundiff-oneseason.stan ran
    on the 2011 season.

    See https://kyleam.github.io/mlb-rundiff/rundiff-oneseason-2011.html
    for a description of this simple "test" model.

    This shouldn't take more than a few minutes to run.

  * outputs/models/rundiff-lagwe_1992-2011-fit.rds

    The Stan fit object for the code/models/rundiff-lagwe.stan model
    ran on the 1992 through 2011 data set.

    See https://kyleam.github.io/mlb-rundiff/ for a description of the
    model.

    This could take a while -- think overnight.

  * site/index.html

    Build the https://kyleam.github.io/mlb-rundiff/ site locally.

    This could take a while -- think overnight.

    Note that, before running this command, the SSA supplemental
    tables must be present.  You can download them with

        $ git annex get inputs/lag/pnas.1608847114.st0{1,2}.docx

Run `snakemake --list` or `snakemake --list-target-rules` to see a
list of all available rules.
"""

from glob import glob
from snakemake.shell import shell

shell.executable("bash")

RSCRIPT="Rscript --no-save --no-restore --no-site-file --no-init-file "


rule help:
    run:
        print(__doc__)


### Initial data processing

rule gamelogs_cut_park_codes:
    input: "inputs/gamelogs/parkcode.txt"
    output: "outputs/parkcode-cut.csv"
    shell: "sed 1d {input} | cut -f1,2 -d, > {output}"

rule gamelogs_extract_person_id:
    input: "inputs/gamelogs/retroID.htm",
    output: "outputs/person-ids.csv"
    shell:  "echo 'id,last,first,debut,debut_m,debut_c,debut_u' > {output} &&"
            "awk 'f;/ID,Last/{{f=1}}' {input} | "
            "awk '/^$/ {{exit}} {{print}}' >> {output}"

rule gamelogs_convert_and_rename_:
    input: "inputs/gamelogs/GL{year}.TXT"
    output: "outputs/gamelogs/{year,[0-9]+}.csv"
    shell: "dos2unix -n {input} {output}"

rule gamelogs_combine_years:
    input: expand("outputs/gamelogs/{year}.csv", year=range(1990, 2016))
    output: "outputs/gamelogs-1990_2016.csv"
    shell: "cat {input} > {output}"

rule gamelogs_pythagorean:
    input: "code/pythagorean.R",
           "outputs/gamelogs-1990_2016.csv",
           "inputs/game-log-header.txt"
    output: "outputs/wins-pythagorean.csv"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "./$(basename {input[0]})"


### Calculation of lag

rule lag_spread_incomplete_:
    input: "code/lag/spread_incomplete.py", "outputs/gamelogs/{year}.csv"
    output: "outputs/gamelogs/{year}-spread.csv"
    shell: "python3 {input[0]} {input[1]} | sort -t, -k1,1 > {output}"

rule lag_calculate_:
    input: "code/lag/lag.py", "outputs/gamelogs/{year}-spread.csv"
    output: "outputs/lag/{year}.csv"
    shell: "python3 {input[0]} {input[1]} > {output}"

rule lag_calculate_with_ht_:
    input: "code/lag/lag.py", "outputs/gamelogs/{year}-spread.csv"
    output: "outputs/lag/{year}-ht.csv"
    shell: "python3 {input[0]} --with-ht {input[1]} > {output}"

rule lag_combine_:
    input: expand("outputs/lag/{year}{{kind}}.csv", year=range(1990, 2016))
    output: "outputs/lag/lag-combined-1990_2016{kind,(|-ht)}.csv"
    shell: "head -n1  {input[0]} > {output} &&"
           "for f in {input}; do sed 1d $f >> {output}; done"

rule lag_join_log_and_lag:
    input: "code/lag/join-log-and-lag.R",
           "outputs/lag/lag-combined-1990_2016.csv",
           "inputs/game-log-header.txt",
           "outputs/gamelogs-1990_2016.csv"
    output: "outputs/lag/log-with-lags.csv"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "./$(basename {input[0]})"

rule lag_clean_log_with_lags:
    input: "code/lag/clean-log-with-lags.R",
           "outputs/lag/log-with-lags.csv"
    output: "outputs/lag/log-with-lags-cleaned.csv"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "./$(basename {input[0]})"

rule lag_convert_song2017how_table_s1_to_md:
    input: "inputs/lag/pnas.1608847114.st01.docx"
    output: "docs/_song2017how-table-s1.md"
    shell: "pandoc -f docx -t markdown {input} |"
           "sed 's/West    /**West**/' | sed 's/East    /**East**/' | "
           "awk '/^$/ {{exit}} {{print}}' > {output}"

rule lag_convert_song2017how_table_s2_to_text:
    input: "inputs/lag/pnas.1608847114.st02.docx"
    output: temp("outputs/lag/song2017how-table-s2.dat")
    shell: "pandoc -f docx -t plain {input} > {output}"

rule lag_convert_song2017how_table_s2_to_csv:
    input: "outputs/lag/song2017how-table-s2.dat"
    output: "outputs/lag/song2017how-table-s2.csv"
    shell: "printf 'date,away,home,away_lag,home_lag\n' > {output}.tmp && "
           "awk '/^ +[0-9]/ {{print}}' {input} | "
           "sed 's/^ \+//g' | sed 's/ \+/,/g' >> {output}.tmp && "
           "mv {output}.tmp {output}"


### Models

rule models_dump_rundiff_oneseason_2011_data:
    input: "code/models/dump-rundiff-oneseason_2011-data.R",
           "outputs/lag/log-with-lags-cleaned.csv"
    output: "outputs/models/rundiff-oneseason_2011.data.R",
            "outputs/models/rundiff-oneseason_2011.info.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_dump_rundiff_split_2011_data:
    input: "code/models/dump-rundiff-split_2011-data.R",
           "code/lib/utils.R",
           "outputs/lag/log-with-lags-cleaned.csv"
    output: "outputs/models/rundiff-split_2011.data.R",
            "outputs/models/rundiff-split_2011.info.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_dump_rundiff_pitch_2011_data:
    input: "code/models/dump-rundiff-pitch_2011-data.R",
           "code/lib/utils.R",
           "outputs/lag/log-with-lags-cleaned.csv"
    output: "outputs/models/rundiff-pitch_2011.data.R",
            "outputs/models/rundiff-pitch_2011.info.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_dump_rundiff_park_2011_data:
    input: "code/models/dump-rundiff-park_2011-data.R",
           "code/lib/utils.R",
           "outputs/lag/log-with-lags-cleaned.csv"
    output: "outputs/models/rundiff-park_2011.data.R",
            "outputs/models/rundiff-park_2011.info.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_dump_rundiff_year_range_data_:
    input: "code/models/dump-rundiff-{name}-data-year-range.R",
           "code/lib/utils.R",
           "outputs/lag/log-with-lags-cleaned.csv"
    output: "outputs/models/rundiff-{name}_{year1}-{year2}.data.R",
            "outputs/models/rundiff-{name}_{year1}-{year2}.info.R"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]}) "
           "{wildcards.year1} {wildcards.year2}"

rule models_dump_rundiff_home_1992_2011_data:
    input: "code/models/dump-rundiff-home_1992-2011-data.R",
           "outputs/lag/log-with-lags-cleaned.csv"
    output: "outputs/models/rundiff-home_1992-2011.data.R",
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_sample_:
    input: "code/models/sample-{model}_{data}.R",
           "code/models/{model}.stan",
           "outputs/models/{model}_{data}.data.R"
    output: protected("outputs/models/{model}_{data}-fit.rds")
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_sim_rundiff_lagwe_1992_2011:
    input: "code/models/sim-rundiff-lagwe_1992-2011.R",
           "code/models/sim-rundiff-lagwe.R",
           "outputs/models/rundiff-lagwe_1992-2011-fit.rds",
           "outputs/models/rundiff-lagwe_1992-2011.info.R",
           "outputs/models/rundiff-lagwe_1992-2011.data.R"
    output: protected("outputs/models/rundiff-lagwe_1992-2011-sim.rds")
    shell: "cd $(dirname {input[0]}) && "
           "time " + RSCRIPT + "$(basename {input[0]})"

rule models_sim_cov_rundiff_lagwe_1992_2011:
    input: "code/models/sim-cov-rundiff-lagwe_1992-2011.R",
           "outputs/models/rundiff-lagwe_1992-2011-sim.rds",
           "outputs/models/rundiff-lagwe_1992-2011.data.R"
    output: "outputs/models/rundiff-lagwe_1992-2011-sim-cov.dat"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_sim_wins_rundiff_lagwe_1992_2011:
    input: "code/models/sim-wins-rundiff-lagwe_1992-2011.R",
           "outputs/models/rundiff-lagwe_1992-2011-sim.rds",
           "outputs/models/rundiff-lagwe_1992-2011.data.R",
           "outputs/models/rundiff-lagwe_1992-2011.info.R"
    output: "outputs/models/rundiff-lagwe_1992-2011-sim-wins.rds"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_sim_rgames_rundiff_lagwe_1992_2011:
    input: "code/models/sim-rgames-rundiff-lagwe_1992-2011.R",
           "outputs/models/rundiff-lagwe_1992-2011-sim.rds",
           "outputs/models/rundiff-lagwe_1992-2011.data.R",
           "outputs/models/rundiff-lagwe_1992-2011.info.R"
    output: "outputs/models/rundiff-lagwe_1992-2011-sim-rgames.rds"
    shell: "cd $(dirname {input[0]}) && " +
           RSCRIPT + "$(basename {input[0]})"

rule models_sim_rundiff_home_1992_2011_data:
    input: "code/models/sim-rundiff-home_1992-2011-data.R",
    output: "outputs/models/rundiff-home_1992-2011-sim.data.R"
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
    "outputs/lag/2011.csv",
    "outputs/lag/lag-combined-1990_2016-ht.csv",
    "outputs/lag/lag-combined-1990_2016.csv",
    "outputs/lag/log-with-lags-cleaned.csv",
    "outputs/lag/song2017how-table-s2.csv",
    "outputs/models/rundiff-home_1992-2011-fit.rds",
    "outputs/models/rundiff-lagwe_1992-2011-fit.rds",
    "outputs/models/rundiff-lagwe_1992-2011-sim-cov.dat",
    "outputs/models/rundiff-lagwe_1992-2011-sim-rgames.rds",
    "outputs/models/rundiff-lagwe_1992-2011-sim-wins.rds",
    "outputs/models/rundiff-lagwe_1992-2011.data.R",
    "outputs/models/rundiff-lagwe_1992-2011.info.R",
    "outputs/models/rundiff-oneseason_2011-fit.rds",
    "outputs/models/rundiff-split_2011-fit.rds",
    "outputs/models/rundiff-split_2011.data.R",
    "outputs/models/rundiff-split_2011.info.R",
    "outputs/parkcode-cut.csv",
    "outputs/person-ids.csv",
    "outputs/wins-pythagorean.csv",
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
