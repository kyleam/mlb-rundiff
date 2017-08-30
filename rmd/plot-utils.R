
theme_colors <- function(){
    list(background_light = "gray92",
         background_dark = "gray30",
         secondary = "gray10",
         ## Purple colors are taken from bayesplot's "purple" color
         ## scheme.
         primary_light_dim = "#e5cce5",
         primary_light = "#bf7fbf",
         primary_dim = "#a64ca6",
         primary = "#800080",
         primary_dark_dim = "#660066",
         primary_dark = "#400040")
}

theme_setup <- function(){
    tc <<- theme_colors()

    theme_set(theme_minimal())
    update_geom_defaults("bar",
                         list(fill = tc$background_light,
                              colour = tc$background_dark,
                              size = 0.3))
    update_geom_defaults("point",
                         list(colour = tc$secondary))
    update_geom_defaults("line",
                         list(colour = tc$secondary))
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
