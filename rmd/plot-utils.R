
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

theme_setup <- function(){
    tc <- theme_colors()

    theme_set(theme_minimal())
    update_geom_defaults("bar",
                         list(fill = tc$background_light,
                              colour = tc$background_dark,
                              size = 0.3))

    tc
}
}

theme_axis_line <- function(){
    theme(panel.grid = element_blank(),
          axis.line = element_line(color = theme_colors()$background_dark,
                                   size = 0.4))
}

theme_histogram <- function(){
    theme(axis.text.y = element_blank(),
          axis.title.y = element_blank(),
          panel.grid = element_blank())
}
