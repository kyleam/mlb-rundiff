
source("utils.R")

test_that("trace_intervals, vector and 1d", {
    x <- 1:11
    result_x <- trace_intervals(x, probs = 0.1)

    expect_equal(length(result_x), 2)
    expect_equal(names(result_x), c("mean", "p10"))
    expect_equal(result_x[["p10"]], 2.)

    a1 <- array(1:11)
    result_a1 <- trace_intervals(a1, probs = 0.1)
    expect_equal(result_x, result_a1)
})


test_that("trace_intervals, > 1d", {
    a2 <- array(1:33, c(11, 3))
    a3 <- array(1:66, c(11, 3, 2))

    result_a2 <- trace_intervals(a2, "var1")
    result_a3 <- trace_intervals(a3, c("var1", "var2"))

    result_a2_names <- names(result_a2)
    expect_true("var1" %in% result_a2_names)
    expect_true("mean" %in% result_a2_names)
    expect_true("p2.5" %in% result_a2_names)

    expect_equal(filter(result_a2, var1 == 1) %>% .$p10,
                 2.)

    expect_equal(setdiff(names(result_a3), result_a2_names),
                 "var2")

    expect_equal(result_a2,
                 filter(result_a3, var2 == 1) %>% select(-var2))
})

test_that("rundiff_pwin", {
    expect_equal(rundiff_pwin(15, 0, 3), 0.5)
    expect_equal(rundiff_pwin(15, 0, 3),
                 rundiff_pwin(15, 0, 3, home = FALSE))

    ## This should be true for probabilities that aren't extreme.
    expect_equal(1 - rundiff_pwin(15, 1, 3),
                 rundiff_pwin(15, 1, 3, home = FALSE))


    ## Sledge hammer approach that's susceptible to random failures.

    ## expect_rand_near <- function(nu, mu, sigma){
    ##     eval(bquote(expect_equal(rundiff_pwin(.(nu), .(mu), .(sigma)),
    ##                              mean((.(mu) + rt(1e5, .(nu)) * .(sigma)) > 0),
    ##                              tolerance = 0.005)))
    ## }

    ## expect_rand_near(5, 0.2, 3)
    ## expect_rand_near(15, 0.2, 3)
    ## expect_rand_near(15, 0.2, 6)
    ## expect_rand_near(15, 2, 3)

})
