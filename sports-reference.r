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

## build full url and only seelct links to schools
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
        ncaa = ifelse(ncaa_tournament == "Won National Final", 128,
        ifelse(ncaa_tournament == "Lost National Final", 64,
        ifelse(ncaa_tournament == "Lost National Semifinal", 32,
        ifelse(ncaa_tournament == "Lost Regional Final (Final Four)", 16,
        ifelse(ncaa_tournament == "Lost Regional Final", 8,
        ifelse(ncaa_tournament == "Lost Regional Semifinal", 4,
        ifelse(ncaa_tournament == "Lost Second Round", 2,
        ifelse(ncaa_tournament == "Lost First Round", 1, 0))))))))
    )

## remove duplicate rows
data <- unique(data)

## save data
readr::write_csv(data, "../data/ncaa-team-data.csv")

## poisson model
m1 <- glm(ncaa ~ wl + pts_total + srs + sos + ap_pre +
              ap_high + ap_final + pts_diff,
          data = dplyr::filter(data, season != "2016-17"),
          family = poisson)

## view results
summary(m1)

## view model results as table
tmp <- tempfile(fileext = ".html")
cat(texreg::htmlreg(m1), file = tmp)
browseURL(tmp)

##--------------------------------------------------------------------------------##
##                             PREDICTIONS FOR 2017                               ##
##--------------------------------------------------------------------------------##

## 2017 data
dat17 <- dplyr::filter(data, season == "2016-17")

## set outcomes to missing
dat17$ncaa <- NA_real_

## get model estimates for 2017 data
dat17$ncaa <- predict(m1, newdata = dat17)

## topline text for readme file
topline <- "## NCAA Men's Basketball Data
A [csv file](https://github.com/mkearney/ncaa_bball_data/raw/master/data/ncaa-team-data.csv) of team-level ncaa data with tournament outcomes included.

## Data preview
"

## data preview
preview <- data %>%
    dplyr::arrange(-pts_diff) %>%
    head(25)
## add preview data to topline
topline <- paste0(topline, knitr::kable(preview), "\n\n\n")

## save predictions table to README.md file
dat17 %>%
    dplyr::select(school, conf, w, l, ncaa) %>%
    dplyr::arrange(-ncaa) %>%
    print(n = 100) %>%
    knitr::kable() %>%
    paste(collapse = "\n") %>%
    paste0(topline, "\n\n## My NCAA model\n\n", .) %>%
    cat(file = "~/r/ncaatourney/README.md", fill = TRUE)
