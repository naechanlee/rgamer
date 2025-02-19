#' @title Find strategies available in an extensive-form game
#' @description \code{extensive_strategy} finds the strategies for each player
#'     in an extensive-form game.
#' @param player A vector of players corresponding to play nodes in the game.
#' @param action_list A list of actions corresponding to play nodes in the game.
#' @param info_sets A list of information sets.
#' @param info_sets_player A vector of players corresponding to each element of
#'     info_sets.
#' @param node_to_play A list whose element shows which nodes each player plays.
#' @return A list of strategies and action_prof
#' @importFrom magrittr %>%
#' @noRd
#' @author Yoshio Kamijo and Yuki Yanai <yanai.yuki@@kochi-tech.ac.jp>
extensive_strategy <- function(player,
                               action_list,
                               info_sets = NULL,
                               info_sets_player = NULL,
                               node_to_play = NULL) {

  u_player <- unique(player)
  n_seq <- length(action_list)

  action_num <- list()
  for (i in 1:length(u_player)) {
    action_seq <- (1:n_seq)[player == u_player[i]]
    action_num[[i]] <- action_seq
  }
  names(action_num) <- u_player

 action_profiles <- strategy_list <- list(NA, NA)
 for (p in 1:length(u_player)) {
   action_num_p <- action_num[[p]]
   actions <- list()
   for (s in action_num_p) {
     actions <- c(actions, list(action_list[[s]]))
   }

   actions_l <- sapply(actions, length)
   tot_rows <- prod(actions_l)
   action_p <- matrix(NA,
                      nrow = tot_rows,
                      ncol = length(actions))
   colnames(action_p) <- paste0("var", 1:length(actions))
   denom <- 1
   for (l in 1:length(actions)) {
     action_p[, l] <- rep(actions[[l]], each = tot_rows / actions_l[[l]])
     tot_rows <- tot_rows / actions_l[[l]]
   }
   action_p <- tibble::as_tibble(action_p)

   a_list <- b_list <- list()
   for (i in 1:nrow(action_p)) {
     a_vec <- unlist(action_p[i, ])
     names(a_vec) <- NULL
     a_list <- c(a_list, list(a_vec))
     b_list <- c(b_list,
                 paste0("(", paste(action_p[i, ], collapse = ", "), ")"))
   }
  action_profiles[[p]] <- a_list
  strategy_list[[p]] <- b_list
  }
  names(action_profiles) <- u_player

  if (!is.null(info_sets)) {
    u_info_player <- unique(info_sets_player)
    for (i in 1:length(u_info_player)) {
      target_p <- u_info_player[i]
      s_num <- which(u_player == target_p)
      action_p <- action_profiles[[target_p]] %>%
        unlist() %>%
        matrix(ncol = length(node_to_play[[s_num]]),
               byrow = TRUE) %>%
        as.data.frame()
      names(action_p) <- paste0("n", node_to_play[[s_num]])

      s_set <- which(info_sets_player == target_p)

      keep_out <- NULL
      for (s in s_set) {
        info <- paste0("n", info_sets[[s]])
        if (length(info) > 1) {
          for (j in 2:length(info)) {
            action_p[, info[j]] <- action_p[, info[1]]
            keep_out <- c(keep_out, info[j])
          }
        }
      }
      keep <- !(names(action_p) %in% keep_out)

      action_p <- dplyr::distinct(action_p) %>%
        tibble::as_tibble()
      strategy_p <- action_p[, keep]
      strategy_tmp <- list()
      for (r in 1:nrow(strategy_p)) {
        strategy_tmp[[r]] <- paste0("(", paste(strategy_p[r, ], collapse = ", "), ")")
      }
      action_p <- as.list(as.data.frame((t(as.matrix(action_p)))))
      names(action_p) <- NULL
      action_profiles[[target_p]] <- action_p
      strategy_list[[s_num]] <- strategy_tmp
    }
  }

  for (i in 1:length(u_player)) {
    strategy_list[[i]] <- unlist(strategy_list[[i]])
  }
  names(strategy_list) <- paste0("s", 1:length(u_player))

  return(list(strategy = strategy_list,
              action_profile = action_profiles))
}
