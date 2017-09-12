sessfile <- paste0(tools::file_path_sans_ext(knitr::current_input()),
                   "-session-info.txt")

sink(sessfile)
print(devtools::session_info())
sink()

cat('<div id="rsession">\n')
cat("<hr>")
cat(paste0('<a href="', sessfile, '"> R session info</a>\n'))
cat("</div>\n")
