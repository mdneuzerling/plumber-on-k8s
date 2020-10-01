library(plumber)
library(promises)
library(future)
future::plan("multiprocess")

pr("plumber.R") %>% pr_run(host='0.0.0.0', port = 8000)
