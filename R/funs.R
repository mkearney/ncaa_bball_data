fct_num <- function(.x) {
  if (all(is.na(.x))) {
    return(as.character(.x))
  }
  if (!is.character(.x)) {
    return(.x)
  }
  .x[is.na(.x)] <- "NA"
  if (tfse::n_uq(.x) == 2) {
    .x <- .x == unique(.x)[1]
  } else if (tfse::n_uq(.x) > 2 && tfse::n_uq(.x) < (.8 * length(.x))) {
    .x <- factor(.x)
  }
  .x
}

x_mat <- function(.y, .x) {
	ychr <- as.character(deparse(substitute(.y)))
  chr <- dapr::vap_lgl(.x, is.character)
  lg <- dapr::vap_lgl(.x, ~ all(tfse::na_omit(.x) %in% c("TRUE", "FALSE")))
  .x[lg & chr] <- dapr::lap(.x[lg & chr], as.logical)
  lg <- dapr::vap_lgl(.x, is.logical)
  .x[lg] <- dapr::lap(.x[lg], as.integer)
  .x[] <- dapr::lap(.x, fct_num)
  .x <- .x[dapr::vap_lgl(.x, ~ is.numeric(.x) | is.factor(.x) | is.logical(.x))]
  kp <- unlist(lapply(.x, function(y) var(as.numeric(y), na.rm = TRUE))) > 0 |
  	names(.x) %in% ychr
  .x <- .x[, kp]
  .x[grep("id$", names(.x))] <- dapr::lap(.x[grep("id$", names(.x))], ~ {
    ifelse(is.na(.x), "NA", .x)
  })
  .x$season <- NULL
  .x$.id <- seq_len(nrow(.x))
  y <- matrix(.x[[ychr]], ncol = 1)
  fm <- as.formula(paste0(ychr, "~ ."))
  .x <- model.matrix(fm, .x)
  .x <- as.matrix(.x)
  list(x = .x[, !colnames(.x) %in% c(".id", "y")], y = y,
    id = .x[, ".id", drop = FALSE])
}

coach_years <- function(x) {
	unlist(purrr::map(unique(x),
		~ seq_len(sum(x == .x))
	))
}
