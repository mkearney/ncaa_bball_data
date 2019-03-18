## scrape sports-reference data

## load packages
library(rvest)
library(dplyr)

## url with links
url <- "http://www.sports-reference.com/cbb/schools/"

## get all links
schools <- xml2::read_html(url) %>%
  rvest::html_nodes("a") %>%
  rvest::html_attr("href")

## build full url and only seelct links to schools
schools <- unique(paste0(
  "http://www.sports-reference.com",
  grep("^/cbb/schools/.*/$", schools, value = TRUE)
))

data2 <- readr::read_csv(
  "https://github.com/mkearney/ncaa_bball_data/raw/master/data/ncaa-team-data.csv"
)

## function to add school name as variable to data frames
addschoolname <- function(x, school) {
  if (is.data.frame(x)) {
    names(x) <- gsub(" ", "_", gsub("[[:punct:]]", "",
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

## function to return data frame for x school
getsched <- function(x) {
  school <- gsub("http://www.sports-reference.com/cbb/schools/|/", "", x)
  x <- x %>%
    xml2::read_html() %>%
    rvest::html_nodes(".sortable") %>%
    rvest::html_table(fill = TRUE)
  if (length(x) == 0)
    return(tbl())
  x <- x[[1]]
  if (any("" %in% names(x))) {
      tmp <- tempfile()
      nms <- gsub("[[:punct:]]", "", as.character(x[1, ]))
      nms <- make.names(tolower(nms), unique = TRUE)
      x <- x[-1, ]
      names(x) <- nms
      write.csv(x, tmp, row.names = FALSE)
      x <- suppressMessages(readr::read_csv(tmp))
  }
  if (!is.recursive(x))
    return(tbl())
  if (nrow(x) > 0) {
    x$school <- school
    tfse::print_complete(school)
  }
  x
}

## wrapper function with fail safe
maddata <- function(x) {
  tryCatch(
    getsched(x),
    error = function(e)
      return(tbl())
  )
}

## iterate over all schools (this takes a while)
dat <- lapply(sort(schools), maddata)

## make character vector
makechr <- function(x) {
  x[, 1:ncol(x)] <- apply(x, 2, as.character)
  x
}


## apply to each column and collapse into one data frame
data <- dplyr::bind_rows(lapply(dat, makechr))
names(data) <- gsub("\\.", "_", names(data))

data <- data[data$ap_pre != "AP Pre" & !is.na(data$ap_pre),]
data[, c("ap_pre", "ap_high", "ap_final")] <- data %>%
  dplyr::select(ap_pre, ap_high, ap_final) %>%
  lapply(function(x)
    ifelse(x == "" | is.na(x),
      30, as.double(x)))

## convert columns to class double
data[, 4:13] <- data %>%
  dplyr::select(w:pts_1) %>%
  lapply(as.double)

## point differential variable
data$pts_diff <- data$pts - data$pts_1

## total points variable
data$pts_total <- data$pts + data$pts_1

## code ncaa outcomes
data <- data %>%
  mutate(ncaa_numeric = ifelse(
    is.na(ncaa_tournament),
    0,
    ifelse(
      ncaa_tournament == "Won National Final",
      9,
      ifelse(
        ncaa_tournament == "Lost National Final",
        8,
        ifelse(
          ncaa_tournament == "Lost National Semifinal",
          7,
          ifelse(
            ncaa_tournament == "Lost Regional Final (Final Four)",
            6,
            ifelse(
              ncaa_tournament == "Lost Regional Final",
              5,
              ifelse(
                ncaa_tournament == "Lost Regional Semifinal",
                4,
                ifelse(
                  ncaa_tournament == "Lost Third Round",
                  3,
                  ifelse(
                    ncaa_tournament == "Lost Second Round",
                    2,
                    ifelse(
                      ncaa_tournament == "Lost First Round",
                      1,
                      ifelse(ncaa_tournament == "Lost Opening Round", 1, 0)
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  ))

## rename and reorganize
data <- data %>%
  dplyr::select(
    school,
    conf,
    rk,
    w:sos,
    pts_for = pts,
    pts_vs = ptsa,
    pts_total,
    ap_pre,
    ap_high,
    ap_final,
    pts_diff,
    ncaa_result = ncaa_tournament,
    ncaa_numeric = ncaa,
    season,
    coaches
  )

## set this year to NA
data$ncaa_numeric[data$season == "2018-19"] <- NA_real_

## remove duplicate rows
data <- unique(data)

## save data
readr::write_csv(data, "data/ncaa-team-data.csv")
