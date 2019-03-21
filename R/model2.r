## install packages
.packages <- c("dplyr", "readr", "xgboost", "tfse", "dapr")
if (any(!packages %in% installed.packages())) {
  install.packages(.packages[!.packages %in% install.packages()])
}
source("R/funs.R")

## read data
data <- readr::read_csv("data/ncaa-team-data.csv")

library(dplyr)

data %>%
	filter(ncaa_tournament > 3) %>%
	tbltools::tabsort(coaches) %>%
	dplyr::filter(n > 1) %>%
	dplyr::pull(coaches) -> top_coaches

dd <- data %>%
	arrange(school, year) %>%
	mutate(coach_year = coach_years(coaches),
		coaches = ifelse(coaches %in% top_coaches, coaches, "NA"),
		coaches = factor(coaches, levels = c(top_coaches, "NA")))

#dy <- filter(data, season == "2018-19")
#dx <- filter(data, season != "2018-19")

data_conf <- dd %>%
	group_by(conf, year) %>%
	summarise_if(is.numeric, mean, na.rm = TRUE) %>%
	select(-ncaa_tournament) %>%
	ungroup()

names(data_conf)[-c(1:2)] <- paste0("conf_", names(data_conf)[-c(1:2)])

m <- x_mat(dd %>% left_join(data_conf))


seq_seed <- function(n) {
	x <- unlist(Map(rep, seq_len(ceiling(length(n) / 4)), 4))
	x[seq_len(length(n))]
}

data_conf$confsum_srs

sqr <- function(x) x^2



dd <- dd %>%
	left_join(data_conf) %>%
	mutate(conf_srs = sqr(tfse::rescale_standard(conf_srs)),
		srs = sqr(tfse::rescale_standard(srs)),
		score = wl_conf * conf_srs,
		score = score + wl * srs) %>%
	group_by(year, conf) %>%
	mutate(conf_sore = mean(score, na.rm = TRUE)) %>%
	group_by(year) %>%
	arrange(desc(score)) %>%
	mutate(rk = seq_seed(score)) %>%
	ungroup()

.x <- select(dd, -ap_final, -conf_ap_final)
.y <- score
dd

m <- x_mat(ncaa_tournament, select(dd, -season, -ap_final, -conf_ap_final,
	-is_ap_final))
this_year <- dd$season == "2018-19"

m1 <- xgboost::xgboost(
  m$x[!this_year, ],
  label = m$y[!this_year, ],
  eta = .15,
  nrounds = 50)

m1 <- xgboost::xgboost(
	m$x[!this_year, ],
  label = m$y[!this_year, ],
  #eta = .50,
	xgb_model = m1,
	nrounds = 100)

## pred influence
m1 %>%
	xgboost::xgb.Booster.complete() %>%
	xgboost::xgb.importance(model = .) %>%
	head(30)

## get predictions
pred <- predict(m1, newdata = m$x, type = "response")

am <- mutate(dd, pred = pred) %>%
	select(school, year, seed, ncaa_tournament, pred) %>%
	filter(year == 2019, seed < 17) %>%
	group_by(seed) %>%
	summarise(pred = mean(pred - 1)) %>%
	ungroup() %>%
	mutate(prob = pred / sum(pred),
		avg_money = prob * 25 * 8) %>%
	select(seed, avg_money)

mutate(dd, pred = pred) %>%
	select(school, year, score, seed, ncaa_tournament, pred) %>%
	filter(year == 2019, seed < 17) %>%
	arrange(desc(pred)) %>%
	mutate(pred = pred - 1,
		prob = pred / sum(pred[1:24]),
		money = prob * 100 * 8) %>%
	left_join(am) %>%
	arrange(desc(pred)) %>%
	select(school, score, seed, pred, money, avg_money) %>%
	mutate_if(is.numeric, round, 2) %>%
	rename(exp_value = money, seed_value = avg_money) %>%
	mutate(rel_value = exp_value - seed_value) %>%
	print(n = 40) %>%
	readr::write_csv("~/Dropbox/ncaa-preds.csv")


saveRDS(bb, "data/bracket.rds")

split_bracket <- function(x) {
  st <- 1
  m <- length(x)
  h <- m / 2
  hh <- (m / 2) + 1
  d <- do.call(rbind, Map(c, x[seq(st, h)], x[c(m:hh)]))
  colnames(d) <- c("home", "away")
  d <- tibble::as_tibble(d)
  d
}

dd
gsub(" ", "-", tolower(bb$school))

dd$overall <- NA_integer_
grep("temp", bb$school, ignore.case = TRUE, value = TRUE)


print(bb, n = 60)

dds <- dd$school[dd$year == 2019]
grep("temp", dds, ignore.case = TRUE)
dds <- sub("louisiana-state", "lsu", dds)
dds <- sub("central-florida", "ucf", dd$school)
dds <- sub("mississippi", "ole-miss", dd$school)
dds <- sub("virginia-commonwealth", "vcu", dd$school)
dds <- sub("louisiana-state", "lsu", dd$school)
dds <- sub("louisiana-state", "lsu", dd$school)
dd$overall[dd$year == 2019] <- bb$overall[match(sub("state", "st.", dd$school[dd$year == 2019]),
	gsub(" ", "-", tolower(bb$school)))]

select(dd, school, year, seed, overall) %>%
	filter(year == 2019, seed < 20) %>%
	arrange(overall) %>%
	print(n = 66)

match(dd$school[dd$year == 2019], gsub(" ", "-", tolower(bb$school)))

foo <- function(i) {
	i <- dd$year == 2019 & dd$overall == i & !is.na(dd$overall)
	dd[i, c("school", "score")]
}
unl_mat <- function(x) {
  unlist(lapply(seq_len(nrow(x)), function(i) c(x[i, ])))
}
foo(64)

tfse::nin(1:64, unl_mat(split_bracket(1:64)))


filter(dd, overall == 57)

ha <- lapply(unl_mat(split_bracket(1:64)), foo)

i <- 5
which(purrr::map_int(ha, nrow) == 0)

for (i in seq_along(ha)) {
	ha[[i]]$place <- names(ha)[i]
}

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
