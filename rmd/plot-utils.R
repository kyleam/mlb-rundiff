
require(ggplot2)

theme_colors <- function(){
    list(background_light = "gray92",
         background = "gray60",
         background_dark = "gray30",
         primary = "#26a65b",
         primary_dark = "#14572F",
         primary_light = "#53B87D",
         primary_lighter = "#bae2cb",
         secondary = "#3f26a6",
         secondary_dark = "#211457",
         secondary_light = "#6753B8",
         secondary_lighter = "#c2bae2")
}

theme_rd <- function(base_size = 11, base_family = ""){
    half_line <- base_size/2
    theme_grey(base_size = base_size, base_family = base_family) %+replace%
        theme(panel.background = element_rect(fill = "white", colour = NA),
              panel.border = element_blank(),
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(),
              axis.line = element_line(color = "gray30", size = 0.4),
              axis.ticks = element_line(colour = "grey30"),
              strip.background = element_rect(fill = "white", colour = NA),
              legend.key = element_rect(fill = "white", colour = NA),
              plot.caption = element_text(size = rel(0.8), color = "gray40",
                                          hjust = 1, vjust = 1,
                                          margin = margin(t = half_line * 0.9)),
              complete = TRUE)
}

theme_setup <- function(){
    tc <- theme_colors()

    theme_set(theme_rd())
    update_geom_defaults("bar",
                         list(fill = tc$background_light,
                              colour = tc$background_dark,
                              size = 0.3))

    tc
}

theme_grid <- function(axis = c("x", "y"), minor = FALSE){
    el <- element_line(colour = "grey92")
    el_minor <- element_line(colour = "grey92", size = 0.25)

    args <- list()
    for (ax in axis){
        args[[paste0("panel.grid.major.", ax)]] <- el
        if (minor)
            args[[paste0("panel.grid.minor.", ax)]] <- el_minor
    }
    do.call(theme, args)
}

theme_remove_axis <- function(axis = c("x", "y"), text = TRUE, title = TRUE){
    args <- list()
    args[[paste0("axis.line.", axis[1])]] <- element_blank()
    args[[paste0("axis.ticks.", axis[1])]] <- element_blank()
    if (text)
        args[[paste0("axis.text.", axis[1])]] <- element_blank()
    if (title)
        args[[paste0("axis.title.", axis[1])]] <- element_blank()
    do.call(theme, args)
}
