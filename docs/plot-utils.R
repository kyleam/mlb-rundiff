
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
              legend.key = element_rect(fill = NA, colour = NA),
              legend.background = element_rect(fill = NA, colour = NA),
              plot.title = element_text(size = rel(1.1),
                                        hjust = 0, vjust = 1,
                                        margin = margin(b = half_line * 1.2)),
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

## Wrapper around annotate("text", ...) that sets `size` to the
## theme's default text size.
##
## Arguments:
##
##   x, y, text: passed to `ggplot2::annotate`.
##
##   font.size: A font size to use instead of the theme's font size or
##              a `rel` object to specify the size relative to the
##              theme's text size.
##
##         ...: arguments to `ggplot2::annotate`.  `geom`, `x`, `y`,
##              `label` and `size` are already set and should not be
##              passed by the caller.
annotate_text <- function(x, y, text, fontsize = NULL, ...){
    th <- theme_get()

    if (is.null(fontsize))
        fontsize = th$text$size
    else if (inherits(fontsize, "rel"))
        fontsize = th$text$size * unclass(fontsize)
    size = fontsize / 2.845276  # ggplot2:::.pt

    annotate("text", x = x, y = y, label = text,
             size = size, ...)
}

## Wrapper around annotate("text", ...) that sets some aesthetics
## based on the value of the theme's plot.caption.
##
## Arguments:
##
##   x, y, text: passed to `ggplot2::annotate`.
annotate_caption <- function(x, y, text){
    th <- theme_get()
    annotate_text(x, y, text,
                  fontsize = th$plot.caption$size,
                  colour = th$plot.caption$colour,
                  hjust = 0)
}
