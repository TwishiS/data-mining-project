## This is the gathering tweets from Twitter part where we use RTWEET
## Installtions
## --------------------------------------------------------
install.packages("rtweet")
install.packages("httpuv")
install.packages("httpr")
install.packages("dplyr")
install.packages("styler")
install.packages("tidyverse")

## install remotes package if it's not already
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}
install.packages("rtweet", repos = "https://ropensci.r-universe.dev")

install.packages("nltk")
install.packages("quanteda", dependencies = TRUE)
install.packages("stringr", dependencies = TRUE)
install.packages("spacyr")
install.packages("text2vec")
install.packages("tidytext")
if (packageVersion("devtools") < 1.6) {
  install.packages("devtools")
}
devtools::install_github("paulhendricks/functools")
install.packages("NLP")
install.packages("tm")
install.packages("textclean")
install.packages("lambda.r")


install.packages("wordcloud")
install.packages("SnowballC")
install.packages("RWeka")
install.packages("ggthemes")

## Invoking the libraries installed
## --------------------------------------------------------
library(rtweet)
library(httpuv)
library(tidyverse)
library(dplyr)
library(readr)

## Authenticating the TWITTER API using RTWEET
## --------------------------------------------------------
authenticate_API <- function() {
  # authenticate the api

  api_key <- "dcQFTJkkQ1oXrNPqcZUtbEKiz"
  api_secret_key <- "MQ4j4paLnkfrCFOXXu7TEgDmg7I8qNaaFwd2QftO7WA7vA0120"
  access_token <- "1119482905858801664-DeJfcagsAiIYPHPggUSjVeqrAX5sbK"
  access_secret_token <- "uHV8UN2Z7vXonx8P8zL69dSj3g1nrEIu0y4UhoQNJtpFq"
  appname <- "DisasterLossAnalysis_TwitterApp"

  auth_setup_default()


  setwd("/Users/twishisaran/Documents/Fall 2022 - CSUN /COMP 541 - Data Mining/Project/DisasterAnalysis")
}

## Function to get the tweets and write into csv file - generates a RAW CSV
## --------------------------------------------------------
gather_tweets <- function(keywords, no_of_tweets, filename) {

  # collecting the tweets in Disaster Tweets DF
  Disaster_tweets <- search_tweets(
    q = keywords,
    n = no_of_tweets,
    include_rts = FALSE,
    retryonratelimit = FALSE,
    lang = "en"
  )

  # getting the data of the users who tweeted about the disasters
  User_Dataset <- users_data(Disaster_tweets)

  TweetsSubset <- c(
    "created_at",
    "id_str",
    "full_text",
    "retweet_count",
    "favorite_count",
    "lang"
  )
  UsersSubset <- c(
    "name",
    "screen_name",
    "followers_count",
    "location",
    "description",
    "verified"
  )
  Tweets <- data.frame(Disaster_tweets[TweetsSubset])
  Users <- data.frame(User_Dataset[UsersSubset])
  Disaster_Tweets_Dataset <- cbind(Tweets, Users) # this is a combined data frame
  rm("Tweets", "Users", "TweetsSubset", "UsersSubset")


  # data frame with tweet and user location and name
  Disaster_Tweets_Dataset$localtime <- as.POSIXct(Disaster_Tweets_Dataset$created_at, tz = "GMT")
  Disaster_Tweets_Dataset$localtime <- format(Disaster_Tweets_Dataset$localtime, tz = "America/Los_Angeles", usetz = TRUE)
  Disaster_Tweets_Dataset$URL <- paste("https://twitter.com/user/status/", Disaster_Tweets_Dataset$id_str, sep = "")
  Disaster_Tweets_Dataset$query <- paste(keywords)

  ## view(Disaster_Tweets_Dataset)

  final_Data_Frame <- select(
    Disaster_Tweets_Dataset,
    "created_at", "id_str", "screen_name", "full_text", "location", "localtime", "URL", "query"
  )


  if (!file.exists(filename)) {
    rlog::log_info("file is created for the first time...") ## logs

    columnnames <- c("created_at", "id_str", "screen_name", "full_text", "location", "localtime", "URL", "query")

    headersData <- data.frame(matrix(nrow = 0, ncol = length(columnnames)))

    # assign column names
    colnames(headersData) <- columnnames

    write_excel_csv(headersData, file = filename, append = TRUE, col_names = TRUE)
  } else {
    rlog::log_info("file is present so we are appending..")
  }

  write_excel_csv(final_Data_Frame,
    file = filename,
    na = "NA",
    append = TRUE,
    col_names = FALSE
  )

  rlog::log_info("file is updated with the tweets")
}


## Pre-processing the data in the RAW CSV file
## --------------------------------------------------------
preprocess_tweets <- function() {
  source("PreprocessingData.R")
}

## Visualising the cleant data
## --------------------------------------------------------

visualize_tweets <- function() {
  source("Visualization.R")
}

## function calls
## --------------------------------------------------------
authenticate_API()
gather_tweets("Hurricane Ian", 10000, "RawTweets.csv")
preprocess_tweets()
visualize_tweets()
