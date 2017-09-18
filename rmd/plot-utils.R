
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
    theme_grey(base_size = base_size, base_family = base_family) %+replace%
        theme(panel.background = element_rect(fill = "white", colour = NA),
              panel.border = element_blank(),
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(),
              axis.line = element_line(color = "gray30", size = 0.4),
              axis.ticks = element_line(colour = "grey30"),
              strip.background = element_rect(fill = "white", colour = NA),
              legend.key = element_rect(fill = "white", colour = NA),
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

theme_histogram <- function(){
    theme(axis.text.y = element_blank(),
          axis.title.y = element_blank())
}
