## install packages
.packages <- c("dplyr", "lme4")
if (any(!packages %in% installed.packages())) {
  install.packages(.packages[!.packages %in% install.packages()])
}

## load packages
library(dplyr)
library(lme4)

## read data
data <- readr::read_csv("data/ncaa-team-data.csv")

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
x_mat <- function(.x) {
  chr <- dapr::vap_lgl(.x, is.character)
  lg <- dapr::vap_lgl(.x, ~ all(tfse::na_omit(.x) %in% c("TRUE", "FALSE")))
  .x[lg & chr] <- dapr::lap(.x[lg & chr], as.logical)
  lg <- dapr::vap_lgl(.x, is.logical)
  .x[lg] <- dapr::lap(.x[lg], as.integer)
  .x[] <- dapr::lap(.x, fct_num)
  .x <- .x[dapr::vap_lgl(.x, ~ is.numeric(.x) | is.factor(.x) | is.logical(.x))]
  kp <- unlist(lapply(.x, function(y) var(as.numeric(y), na.rm = TRUE))) > 0 |
  	names(.x) %in% "ncaa_tournament"
  .x <- .x[, kp]
  #.x[grep("id$", names(.x))] <- dapr::lap(.x[grep("id$", names(.x))], as.character)
  .x[grep("id$", names(.x))] <- dapr::lap(.x[grep("id$", names(.x))], ~ {
    ifelse(is.na(.x), "NA", .x)
  })
  .x$season <- NULL
  .x$.id <- seq_len(nrow(.x))
  y <- matrix(.x$ncaa_tournament, ncol = 1)
  .x <- model.matrix(ncaa_tournament ~ ., .x)
  .x <- as.matrix(.x)
  list(x = .x[, !colnames(.x) %in% c(".id", "y")], y = y,
    id = .x[, ".id", drop = FALSE])
}

tibble::as_tibble(head(x_mat(data)$x))

x <- c("a", "a", "a", "a", "b", "c", "d", "d", "d", "e")
coach_years <- function(x) {
	unlist(purrr::map(unique(x),
		~ seq_len(sum(x == .x))
	))
}

data <- data %>%
	arrange(school, year) %>%
	mutate(coach_year = coach_years(coaches))

dy <- filter(data, season == "2018-19")
dx <- filter(data, season != "2018-19")

data_conf <- data %>%
	group_by(conf, year) %>%
	summarise_if(is.numeric, mean, na.rm = TRUE) %>%
	select(-ncaa_tournament) %>%
	ungroup()

names(data_conf)[-c(1:2)] <- paste0("confsum_", names(data_conf)[-c(1:2)])

dd <- x_mat(select(data, -coaches) %>% left_join(data_conf))
this_year <- data$season == "2018-19"

m1 <- xgboost::xgboost(
  dd$x[!this_year, ],
  label = dd$y[!this_year, ],
  eta = .20,
  nrounds = 10)

## pred influence
xgboost::xgb.importance(model = xgboost::xgb.Booster.complete(m1)) %>% head(40)

## get predictions
pred <- predict(m1, newdata = dd$x, type = "response")

am <- mutate(data, pred = pred) %>%
	select(school, year, seed, ncaa_tournament, pred) %>%
	filter(year == 2019, seed < 17) %>%
	group_by(seed) %>%
	summarise(pred = mean(pred - 1)) %>%
	ungroup() %>%
	mutate(prob = pred / sum(pred),
		avg_money = prob * 25 * 8) %>%
	select(seed, avg_money)

mutate(data, pred = pred) %>%
	select(school, year, seed, ncaa_tournament, pred) %>%
	filter(year == 2019, seed < 17) %>%
	arrange(desc(pred)) %>%
	mutate(pred = pred - 1,
		prob = pred / sum(pred[1:24]),
		money = prob * 100 * 8) %>%
	left_join(am) %>%
	arrange(desc(pred)) %>%
	select(school, seed, pred, money, avg_money) %>%
	mutate_if(is.numeric, round, 2) %>%
	rename(exp_value = money, seed_value = avg_money) %>%
	mutate(rel_value = exp_value - seed_value) %>%
	readr::write_csv("~/Dropbox/ncaa-preds.csv")


am <- mutate(data, pred = pred) %>%
	select(school, year, seed, ncaa_tournament, pred) %>%
	filter(year == 2018, seed < 17) %>%
	group_by(seed) %>%
	summarise(pred = mean(pred - 1)) %>%
	ungroup() %>%
	mutate(prob = pred / sum(pred),
		prob2 = prob^2 / sum(prob^2),
		avg_money = prob * 25 * 8) %>%
	select(seed, avg_money)
mutate(data, pred = pred) %>%
	select(school, year, seed, ncaa_tournament, pred) %>%
	filter(year == 2018, seed < 17) %>%
	mutate(pred = pred - 1,
		prob = pred / sum(pred),
		prob2 = prob^2 / sum(prob^2),
		money = prob * 100 * 8) %>%
	left_join(am) %>%
	arrange(desc(pred)) %>%
	select(school, seed, ncaa_tournament, pred, money, avg_money) %>%
	print(n = 50)


pred <- predict(m1, newdata = x_mat(dx)$x, type = "response")

mutate(dx, pred = pred) %>%
	select(school, year, ncaa_tournament, pred) %>%
	mutate(error = pred - ncaa_tournament) %>%
	filter(ncaa_tournament > 0, year > 2010) %>%
	arrange(desc(abs(error))) %>%
	print(n = 50)



table(data$year)
lapply(d2, function(x) sum(is.na(x)))


data[x_mat(d2)$id[, 1], c("school", "season")] %>%
  mutate(pred = pred) %>%
  filter(season == "2018-19") %>%
  arrange(desc(pred))

tibble::tibble(actual = y[test_rows, ], pred = round(pred, 0)) %>%
  mutate(error = actual - pred) %>%
  arrange(error) %>%
  print(n = 100)





## poisson model
m1 <- glm(ncaa_numeric ~ .,
      data = dplyr::select(data, -coaches, -school),
      family = poisson)

xgboost::xgb.train()
## results
summary(m1)
data
## multilevel model
m2 <- lme4::lmer(ncaa_numeric ~ . + (1 | season),
       data = dplyr::select(data, -coaches, -school))
## results
##summary(m2)


##----------------------------------------------------------##
##         PREDICTIONS FOR 2017             ##
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
