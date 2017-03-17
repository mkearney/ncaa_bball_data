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
schools <- paste0(
    "http://www.sports-reference.com",
    grep("^/cbb/schools/.*/$", schools, value = TRUE))

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
        x <- as_data_frame(x)
        x$school <- school
    } else {
        x <- tbl()
    }
    x
}

## function for empty tbl
tbl <- function() tbl_df(data.frame())

## function to return data frame for x school
getsched <- function(x) {
    school <- gsub(
        "http://www.sports-reference.com/cbb/schools/|/", "", x)
    x <- x %>%
        read_html(x) %>%
        html_nodes(".sortable") %>%
        html_table(fill = TRUE)
    if (length(x) == 0) return(tbl())
    if (!is.recursive(x)) return(tbl())
    x <- lapply(x, addschoolname, school = school)
    bind_rows(x)
}

## wrapper function with fail safe
maddata <- function(x) {
    tryCatch(getsched(x), error = function(e) return(tbl()))
}

## iterate over all schools (this takes a while)
dat <- lapply(schools, maddata)

## make character vector
makechr <- function(x) {
    x[, 1:ncol(x)] <- apply(x, 2, as.character)
    x
}

## apply to each column
dat <- lapply(dat, makechr)

## collapse into one data frame
data <- bind_rows(dat)
data <- data[data$ap_pre != "AP Pre" & !is.na(data$ap_pre), ]
data[, c("ap_pre", "ap_high", "ap_final")] <- data %>%
    dplyr::select(ap_pre, ap_high, ap_final) %>%
    lapply(function(x) ifelse(x == "" | is.na(x),
                              30, as.double(x)))

## convert columns to class double
data[, 4:10] <- data %>%
    dplyr::select(w:ptsa) %>%
    lapply(as.double)

## point differential variable
data$pts_diff <- data$pts - data$ptsa

## total points variable
data$pts_total <- data$pts + data$ptsa

## code ncaa outcomes
data <- data %>%
    mutate(
        ncaa_numeric = ifelse(is.na(ncaa_tournament), 0,
                       ifelse(ncaa_tournament == "Won National Final", 48,
                       ifelse(ncaa_tournament == "Lost National Final", 40,
                       ifelse(ncaa_tournament == "Lost National Semifinal", 32,
                       ifelse(ncaa_tournament == "Lost Regional Final (Final Four)", 24,
                       ifelse(ncaa_tournament == "Lost Regional Final", 16,
                       ifelse(ncaa_tournament == "Lost Regional Semifinal", 8,
                       ifelse(ncaa_tournament == "Lost Third Round", 4,
                       ifelse(ncaa_tournament == "Lost Second Round", 2,
                       ifelse(ncaa_tournament == "Lost First Round", 1,
                       ifelse(ncaa_tournament == "Lost Opening Round", 1, 0)))))))))))
    )

## rename and reorganize
data <- data %>%
    dplyr::select(school, conf, rk, w:sos, pts_for = pts, pts_vs = ptsa, pts_total,
                  ap_pre, ap_high, ap_final, pts_diff,
                  ncaa_result = ncaa_tournament, ncaa_numeric = ncaa,
                  season, coaches)

## set this year to NA
data$ncaa_numeric[data$season == "2016-17"] <- NA

## remove duplicate rows
data <- unique(data)

## save data
readr::write_csv(data, "../data/ncaa-team-data.csv")

