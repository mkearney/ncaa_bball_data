## install packages
.packages <- c("dplyr", "lme4", "youstacould")
if (any(!packages %in% installed.packages())) {
    install.packages(.packages[!.packages %in% install.packages()])
}

## load packages
library(dplyr)
library(lme4)

## read data
data <- readr::read_csv("../data/ncaa-team-data.csv")

## create year variable
data$year <- as.double(substr(data$season, 1, 4))

## poisson model
m1 <- glm(ncaa_numeric ~ wl * sos + pts_total + srs + ap_pre +
              ap_high + pts_diff,
          data = dplyr::filter(data, season != "2016-17"),
          family = poisson)
## results
##summary(m1)

## multilevel model
m2 <- lmer(ncaa_numeric ~ wl * sos + pts_total + srs + ap_pre +
              ap_high + pts_diff + (1 | season),
           data = dplyr::filter(data, season != "2016-17"))
## results
##summary(m2)


##----------------------------------------------------------##
##               PREDICTIONS FOR 2017                       ##
##----------------------------------------------------------##

## 2017 data
dat17 <- data %>%
    dplyr::filter(ncaa_result %in% c("Playing First Round",
                                     "Playing First Four"))

#dat17 <- dat17[dat17$school %in% model.frame(m2)[["school"]], ]
#dat17 <- dat17[dat17$conf %in% model.frame(m2)[["conf"]], ]

## get model estimates for 2017 data
dat17$ncaa_glm <- predict(m1, newdata = dat17, type = "response")
dat17$ncaa_mlm <- predict(m2, newdata = dat17, type = "response",
                          allow.new.levels = TRUE)

## topline text for readme file
topline <- "## NCAA Men's Basketball Data
A [csv file](https://github.com/mkearney/ncaa_bball_data/raw/master/data/ncaa-team-data.csv) of team-level ncaa data with tournament outcomes included.

## Data preview
"

## data preview
preview <- data %>%
    dplyr::arrange(-pts_diff) %>%
    select(school, conf, season, wl, sos, pts_diff, ncaa_result) %>%
    head(10) %>%
    knitr::kable() %>%
    paste(collapse = "\n")
## add preview data to topline
topline <- paste0(topline, preview, "\n\n\n")

## save predictions table to README.md file
dat17 %>%
    dplyr::select(school, conf, wl, sos, ap_pre, ncaa_mlm) %>%
    dplyr::arrange(-ncaa_mlm) %>%
    knitr::kable() %>%
    paste(collapse = "\n") %>%
    paste0(topline, "\n\n## My NCAA model (multilevel model prediction estimates)\n\n", .) %>%
    cat(file = "~/r/ncaatourney/README.md", fill = TRUE)
