## scrape sports-reference data

## load packages
library(rvest)
library(dplyr)

## url with links
url <- "http://www.sports-reference.com/cbb/schools/"

## get all links
schools <- read_html(url) %>%
  html_nodes("a") %>%
  html_attr("href")

## build full url and only select links to schools
schools <- unique(paste0(
  "http://www.sports-reference.com",
  grep("^/cbb/schools/.*/$", schools, value = TRUE)))

## function to add school name as variable to data frames
addschoolname <- function(x, school) {
  if (is.data.frame(x)) {
    names(x) <- gsub(
      " ", "_", gsub("[[:punct:]]", "",
               tolower(names(x))))
    if (any(duplicated(names(x)))) {
      dups <- names(x)[duplicated(names(x))]
      dups <- paste0(dups, letters[seq_len(length(dups))])
      names(x)[duplicated(names(x))] <- dups
    }
    x <- tibble::as_tibble(x)
    x$school <- school
  } else {
    x <- tbl()
  }
  x
}

## function for empty tbl
tbl <- function() tibble::tibble()

## function to check for data frame
is_one_df <- function(x) {
	length(x) == 1 && is.data.frame(x[[1]])
}

reformat_csv_table <- function(x) {
	if (is.list(x[[1]]) && is.data.frame(x[[1]])) {
		x <- x[[1]]
	}
	if (nrow(x) == 0) {
		return(tbl())
	}
	tmp <- tempfile()
	## reformat names
  nms <- gsub("[[:punct:]]", "", as.character(x[1, ]))
  nms <- make.names(tolower(nms), unique = TRUE)
  nms <- gsub("\\.", "_", nms)
  srs <- grep("srs", nms)
  ## remove header row
  x <- x[-1, ]
  ## remove header lines
  x <- x[grep("SRS", x[[srs]], invert = TRUE), ]
  ## remove asterisks
  x[] <- lapply(x, function(.x) sub("(?<=\\d)\\*+$", "", .x, perl = TRUE))
  ## assign names
  names(x) <- nms
  ## write CSV
  write.csv(x, tmp, row.names = FALSE)
  ## re-read with readr
  x <- suppressMessages(readr::read_csv(tmp))
  ## drop rk var
  x$rk <- NULL
  ## add seed dummy and fill in missing
  x$seeded <- !is.na(x$seed)
  x$seed[is.na(x$seed)] <- 20
  ## clean up coach name
  x$coaches <- sub(" \\(\\d.*", "", x$coaches)
  ## add year variable
  x$year <- as.integer(
		paste0(substr(x$season, 1, 2), substr(x$season, 6, 7))
	)
	## AP dummy vars
	x$is_ap_pre <- !is.na(x$ap_pre)
	x$ap_pre[is.na(x$ap_pre)] <- 30

	x$is_ap_high <- !is.na(x$ap_high)
	x$ap_high[is.na(x$ap_high)] <- 30

	x$is_ap_final <- !is.na(x$ap_final)
	x$ap_final[is.na(x$ap_final)] <- 30

	## point differential variable
	x$pts_diff <- x$pts - x$pts_1

  ## rename and return
  dplyr::rename(x,
  	w_conf = w_1,
  	l_conf = l_1,
  	wl_conf = wl_1,
  	pts_vs = pts_1)
}


## function to return data frame for x school
getsched <- function(url) {
	school <- gsub(".*schools/|/$", "", url)
  x <- url %>%
    xml2::read_html() %>%
    rvest::html_nodes(".sortable") %>%
    rvest::html_table(fill = TRUE)
  if (!is_one_df(x)) {
  	return(tbl())
	}
	tfse::print_complete(school)
	x <- reformat_csv_table(x)
	x$school <- school
  x
}

## wrapper function with fail safe
maddata <- function(x) {
  tryCatch(getsched(x), error = function(e) return(tbl()))
}

## use future apply package to make this lightening fast
library("future.apply")
plan(multiprocess)

## iterate over all schools (this takes a while)
dat <- future_lapply(schools, maddata)

purrr::map_lgl(dat, ~ is.character(.x$w_conf))
sub("(?<=\\d)\\*$", "", dat[[11]]$w_conf, perl = TRUE)

## collapse into one data frame
data <- dplyr::bind_rows(dat)

## ap dummies

## drop rows w/o points
data <- dplyr::filter(data, !is.na(pts))

## conference level
data_conf <- data %>%
	group_by(conf) %>%
	summarise_if(is.numeric, mean, na.rm = TRUE)

## school level
data_school <- data %>%
	group_by(school) %>%
	summarise_if(is.numeric, mean, na.rm = TRUE)

impute_conf_missing <- function(x, var) {
	#var <- as.character(deparse(substitute(var)))
	na <- is.na(x[[var]])
	conf_val <- data_conf[[var]][match(x$conf, data_conf$conf)]
	x[[var]][na] <- conf_val[na]
	x
}

vars <- c(grep("^._conf", names(data), value = TRUE),
	"pts_vs", "srs", "sos")
for (i in seq_along(vars)) {
	data <- impute_conf_missing(data, vars[i])
}

data <- data %>%
	mutate(wl_conf = ifelse(is.na(wl_conf), w_conf - l_conf, wl_conf),
		pts_diff = ifelse(is.na(pts_diff), pts - pts_vs, pts_diff))

data <- dplyr::filter(data, !is.na(srs))

purrr::map_int(data, ~ sum(is.na(.x)))

## total points variable
data$pts_total <- data$pts + data$pts_vs

## code ncaa outcomes
data <- data %>%
  dplyr::mutate(
    ncaa_tournament = ifelse(is.na(ncaa_tournament), 0,
             ifelse(ncaa_tournament == "Won National Final", 9,
             ifelse(ncaa_tournament == "Lost National Final", 8,
             ifelse(ncaa_tournament == "Lost National Semifinal", 7,
             ifelse(ncaa_tournament == "Lost Regional Final (Final Four)", 6,
             ifelse(ncaa_tournament == "Lost Regional Final", 5,
             ifelse(ncaa_tournament == "Lost Regional Semifinal", 4,
             ifelse(ncaa_tournament == "Lost Third Round", 3,
             ifelse(ncaa_tournament == "Lost Second Round", 2,
             ifelse(ncaa_tournament == "Lost First Round", 1,
             ifelse(ncaa_tournament == "Lost Opening Round", 1, 0)))))))))))
  )

## set this year to NA
#data$ncaa_numeric[data$season == "2016-17"] <- NA

## remove duplicate rows
data <- unique(data)

## save data
readr::write_csv(data, "data/ncaa-team-data.csv")

