
source("utils.R")

test_that("trace_intervals", {
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
