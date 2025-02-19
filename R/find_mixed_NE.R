#' @title Find a mixed-strategy Nash equilibrium.
#' @description \code{find_mixed_NE} finds a mixed-strategy Nash equilibrium of
#'     a normal-form game with discrete-choice strategies.
#' @return A list of the probabilities given to each strategy that specifies
#'     the mixed-strategy Nash equilibrium and a list of mixed-strategy Nash
#'     equalibrium of the subsets of strategies..
#' @param game A "normal_form" class object created by \code{normal_form()}.
#'     The game's type must be "matrix".
#' @seealso \code{\link{normal_form}}
#' @noRd
#' @author Yoshio Kamijo and Yuki Yanai <yanai.yuki@@kochi-tech.ac.jp>
find_mixed_NE <- function(game) {

  s1 <- game$strategy[[1]]
  s2 <- game$strategy[[2]]
  p1 <- game$payoff[[1]]
  p2 <- game$payoff[[2]]

  if (length(s1) < 2 | length(s2) < 2) {
    stop("find_mixed_NE() doesn't work for a game with a single-strategy player.")
  }

  find_sets <- function(s) {
    s <- as.list(s)
    2:length(s) %>%
      lapply(function(x) apply(utils::combn(s, x), 2, function(y) y)) %>%
      unlist(recursive = FALSE) %>%
      lapply(unlist)
  }
  s1_sets <- find_sets(s1)
  s2_sets <- find_sets(s2)

  pair <- expand.grid(row = 1:length(s1_sets),
                      col = 1:length(s2_sets))

  msNE_list <- NULL

  for (k in 1:nrow(pair)) {

    s1_sub <- s1_sets[[pair$row[k]]]
    s2_sub <- s2_sets[[pair$col[k]]]

    mat1 <- game$mat$matrix1[s1 %in% s1_sub, s2 %in% s2_sub]
    mat2 <- game$mat$matrix2[s1 %in% s1_sub, s2 %in% s2_sub]

    n_rows <- length(s1_sub)
    n_cols <- length(s2_sub)

    a1 <- matrix(NA, nrow = n_cols, ncol = n_rows)
    b1 <- matrix(NA, nrow = n_cols, ncol = 1)
    a1[1, ] <- 1
    b1[1, 1] <- 1
    for (i in 2:n_cols) {
      a1[i, ] <- mat2[, (i - 1)] - mat2[, i]
      b1[i, 1] <- 0
    }
    prob1 <- tryCatch({
      solve(a1, b1)
    }, error = function(e) {
     NULL
    })

    a2 <- matrix(NA, nrow = n_rows, ncol = n_cols)
    b2 <- matrix(NA, nrow = n_rows, ncol = 1)
    a2[1, ] <- 1
    b2[1, 1] <- 1
    for (i in 2:n_rows) {
      a2[i, ] <- mat1[(i - 1), ] - mat1[i,]
      b2[i, 1] <- 0
    }
    prob2 <- tryCatch({
      solve(a2, b2)
    }, error = function(e) {
    NULL
    })

    if (is.null(prob1) | is.null(prob2)) {
      msNE <- NULL
    } else {
      prob1 <- as.vector(prob1)
      prob2 <- as.vector(prob2)

      if (!all(prob1 >= 0) | !all(prob1 <= 1) |
          !all(prob2 >= 0) | !all(prob2 <=1)) {
        msNE <- NULL
      } else {
        msNE <- list(s1 = prob1, s2 = prob2)
      }
    }
    msNE_list[[k]] <- list(s1 = s1_sub,
                           s2 = s2_sub,
                           msNE = msNE)
  }

  return(list(msNE = msNE, msNE_list = msNE_list))
}
