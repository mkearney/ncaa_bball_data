## NCAA Men's Basketball Data
A [csv file](https://github.com/mkearney/ncaa_bball_data/raw/master/data/ncaa-team-data.csv) of team-level ncaa data with tournament outcomes included.

## Data preview
|school     |conf |season  |    wl|   sos| pts_diff|ncaa_result             |
|:----------|:----|:-------|-----:|-----:|--------:|:-----------------------|
|duke       |ACC  |1998-99 | 0.949| 10.14|     24.6|Lost National Final     |
|gonzaga    |WCC  |2016-17 | 0.970|  2.36|     23.4|Playing First Round     |
|kentucky   |SEC  |1948-49 | 0.941|    NA|     23.2|Won National Final      |
|kentucky   |SEC  |1995-96 | 0.944| 10.06|     22.0|Won National Final      |
|duke       |ACC  |1997-98 | 0.889|  9.33|     21.5|Lost Regional Final     |
|kentucky   |SEC  |1996-97 | 0.875|  9.20|     20.3|Lost National Final     |
|duke       |ACC  |2000-01 | 0.897| 11.98|     20.2|Won National Final      |
|kentucky   |SEC  |2014-15 | 0.974|  8.67|     20.1|Lost National Semifinal |
|louisville |AAC  |2013-14 | 0.838|  4.80|     19.9|Lost Regional Semifinal |
|duke       |ACC  |2001-02 | 0.886|  9.16|     19.7|Lost Regional Semifinal |




## My NCAA model

|school                    |conf      |    wl|   sos| ap_pre|   ncaa_mlm|
|:-------------------------|:---------|-----:|-----:|------:|----------:|
|kansas                    |Big 12    | 0.875| 12.39|      3| 17.6105725|
|villanova                 |Big East  | 0.912|  9.91|      4| 16.7695024|
|kentucky                  |SEC       | 0.853|  9.90|      2| 16.2008208|
|duke                      |ACC       | 0.771| 11.66|      1| 15.7454001|
|north-carolina            |ACC       | 0.794| 11.70|      6| 14.7166157|
|oregon                    |Pac-12    | 0.853|  7.48|      5| 14.1132419|
|arizona                   |Pac-12    | 0.882|  7.61|     10| 13.2653849|
|louisville                |ACC       | 0.750| 12.07|     13| 12.0548911|
|virginia                  |ACC       | 0.688| 11.35|      8| 11.8882056|
|wisconsin                 |Big Ten   | 0.735|  8.89|      9| 11.6001659|
|ucla                      |Pac-12    | 0.879|  5.85|     16| 10.7362318|
|xavier                    |Big East  | 0.618| 11.21|      7| 10.6679073|
|gonzaga                   |WCC       | 0.970|  2.36|     14| 10.3470524|
|purdue                    |Big Ten   | 0.781|  8.40|     15| 10.0503794|
|west-virginia             |Big 12    | 0.765|  9.18|     20|  9.1508602|
|baylor                    |Big 12    | 0.781| 12.00|     30|  8.3973735|
|creighton                 |Big East  | 0.735|  9.20|     22|  8.1629539|
|michigan-state            |Big Ten   | 0.576| 10.37|     12|  8.0670749|
|saint-marys-ca            |WCC       | 0.875|  1.68|     17|  7.7402880|
|iowa-state                |Big 12    | 0.697| 11.85|     24|  6.8783858|
|maryland                  |Big Ten   | 0.750|  8.35|     25|  6.6960219|
|florida-state             |ACC       | 0.758|  9.54|     30|  6.5586993|
|florida                   |SEC       | 0.750| 10.53|     30|  6.3688666|
|butler                    |Big East  | 0.742| 10.46|     30|  6.2985980|
|notre-dame                |ACC       | 0.735| 10.15|     30|  5.8383706|
|cincinnati                |AAC       | 0.853|  5.03|     30|  5.7364837|
|southern-methodist        |AAC       | 0.882|  4.41|     30|  5.6801785|
|rhode-island              |A-10      | 0.727|  4.07|     23|  5.1510566|
|minnesota                 |Big Ten   | 0.727|  9.10|     30|  4.6732296|
|south-carolina            |SEC       | 0.688|  8.63|     30|  4.5100438|
|virginia-tech             |ACC       | 0.688|  8.74|     30|  4.1158076|
|michigan                  |Big Ten   | 0.686|  9.56|     30|  4.0392509|
|arkansas                  |SEC       | 0.735|  8.12|     30|  4.0193251|
|wichita-state             |MVC       | 0.882|  2.24|     30|  3.9396729|
|southern-california       |Pac-12    | 0.727|  5.68|     30|  3.6883352|
|northwestern              |Big Ten   | 0.676|  8.18|     30|  3.5450787|
|miami-fl                  |ACC       | 0.656| 10.11|     30|  3.3495250|
|seton-hall                |Big East  | 0.656|  9.50|     30|  3.1840471|
|dayton                    |A-10      | 0.774|  3.98|     30|  3.0884987|
|illinois-state            |MVC       | 0.818|  2.78|     30|  3.0653947|
|oklahoma-state            |Big 12    | 0.625| 12.00|     30|  3.0533764|
|virginia-commonwealth     |A-10      | 0.765|  3.68|     30|  2.8744648|
|kansas-state              |Big 12    | 0.606| 10.31|     30|  2.8346408|
|nevada                    |MWC       | 0.824|  1.61|     30|  2.5118700|
|providence                |Big East  | 0.625|  8.21|     30|  2.4225528|
|marquette                 |Big East  | 0.613|  8.75|     30|  2.2259922|
|wake-forest               |ACC       | 0.594| 10.27|     30|  2.1732670|
|vanderbilt                |SEC       | 0.559| 10.71|     30|  1.6862062|
|north-carolina-wilmington |CAA       | 0.853| -0.99|     30|  1.4933315|
|middle-tennessee          |CUSA      | 0.882| -1.35|     30|  1.4876711|
|princeton                 |Ivy       | 0.793| -2.32|     30|  0.8161832|
|east-tennessee-state      |Southern  | 0.794| -2.54|     30|  0.6139347|
|monmouth                  |MAAC      | 0.818| -2.94|     30|  0.4885600|
|kent-state                |MAC       | 0.629| -2.00|     30|  0.4124058|
|bucknell                  |Patriot   | 0.765| -3.19|     30|  0.3229036|
|vermont                   |AEC       | 0.853| -3.79|     30|  0.2480059|
|iona                      |MAAC      | 0.647| -3.01|     30|  0.1565354|
|troy                      |Sun Belt  | 0.611| -3.89|     30|  0.0557767|
|jacksonville-state        |OVC       | 0.588| -3.89|     30|  0.0485584|
|mount-st-marys            |NEC       | 0.559| -4.11|     30| -0.0298435|
|new-orleans               |Southland | 0.645| -5.37|     30| -0.2197793|
|new-mexico-state          |WAC       | 0.848| -4.80|     30| -0.2362494|
|north-dakota              |Big Sky   | 0.710| -6.22|     30| -0.5803216|
|winthrop                  |Big South | 0.813| -6.70|     30| -1.0713278|
|texas-southern            |SWAC      | 0.676| -8.52|     30| -1.1722294|
