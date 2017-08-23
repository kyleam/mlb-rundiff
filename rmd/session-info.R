sessfile <- paste0(tools::file_path_sans_ext(knitr::current_input()),
                   "-session-info.txt")

sink(sessfile)
print(devtools::session_info())
sink()

cat(paste0("[R session info](./", sessfile, ")\n"))
