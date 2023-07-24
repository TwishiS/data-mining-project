## Pre-processing
install.packages("tidygeocoder")
devtools::install_github("jessecambon/tidygeocoder")
install.packages("ggmap")
## ---------------------------------------------
library(rtweet)
library(httpuv)
library(tidyverse)
library(dplyr)
library(readr)
library(NLP)
library(lambda.r)
library(tm)
library(textclean)
library(tidygeocoder)
library(ggmap)


setwd("/Users/twishisaran/Documents/Fall 2022 - CSUN /COMP 541 - Data Mining/Project/DisasterAnalysis/CrisisNLP_TrainingDataset")

## Functions for Preprocessing
## -------------------------------------------

replaceTags <- function(text) {
  text <- gsub("(RT|via)((?:\\b\\W*@\\w+)+)", " ", text)
  text <- gsub("@\\w+", " ", text)
  text <- gsub("rt "," ",text)
}

replaceURL <- function(text) {
  text <- replace_url(text, replacement = " ")
}

replaceAmp <- function(text) {
  text <- gsub("&amp", " ", text)
}

replaceHashtags <- function(text) {
  text <- str_replace_all(text, "#[a-z,A-Z]*", " ")
}

replaceUnicode <- function(text) {
  text <- gsub("[^\u0001-\u007F]+|<U\\+\\w+>", " ", text)
}

replaceNewLine <- function(text) {
  text <- gsub("[\r\n]", " ", text)
}

replaceContraction <- function(text) {
  text <- replace_contraction(text, contraction.key = lexicon::key_contractions)
  text <- str_replace_all(text, "here's", "here is")
  text <- str_replace_all(text, "Here's", "Here is")
}

replaceMisc <- function(text) {
  text <- replace_incomplete(text, replacement = " ")
  text <- replace_date(text, replacement = " ")
  text <- replace_email(text)
  text <- replace_grade(text)
  text <- replace_internet_slang(text)
  text <- str_replace_all(text, "([0-9]+[\\w]*)", " ")
}

replaceEmoticons <- function(text) {
  text <- replace_emoji(text)
  text <- replace_emoji(text)
  text <- replace_non_ascii(text)
}

replacePunctuation <- function(text) {
  text <- gsub("[[:punct:] ]+", " ", text)
}

removeWhitespaces <- function(text) {
  text <- str_squish(text)
}

removeSingleWords <- function(text) {
  text <- gsub("\\b[A-z]\\b{1}", " ", text)
}

tokenizeTheTweets <- function(text) {
  text <- tokenize_tweets(text)
}

removeTextElongations <- function(text) {
  text <- replace_word_elongation(text, impart.meaning = TRUE)
}

replacePunctuationForLocation <- function(text) {
  text <- gsub("/", ",", text)
  text <- gsub("\\+.*", "", text)
  text <- gsub("[.]", "", text)
  text <- gsub("\\b[,]\\b{1}", "", text)
  text <- sub("([,])|[[:punct:]]", "\\1", text)
}



## Basic Preprocessing on TrainingDataset CrisinNLP
## --------------------------------------------

filenames <- list.files(path="/Users/twishisaran/Documents/Fall 2022 - CSUN /COMP 541 - Data Mining/Project/DisasterAnalysis/CrisisNLP_TrainingDataset",
                        pattern="*.csv")
data <- do.call("rbind",lapply(filenames,FUN=function(files){ read.csv(files)}))

## view(dataset)

data.text <- iconv(data$tweet_text, to = "utf-8")
text_corpus <- Corpus(VectorSource(data.text))


## Data Cleaning
## ---------------------------------------
rlog::log_info("starting the basic data cleaning...")

text_corpus <- tm_map(text_corpus, tolower)
text_corpus <- tm_map(text_corpus, content_transformer(replaceTags))
text_corpus <- tm_map(text_corpus, content_transformer(replaceURL))
text_corpus <- tm_map(text_corpus, content_transformer(replaceAmp))
text_corpus <- tm_map(text_corpus, content_transformer(replaceHashtags))
text_corpus <- tm_map(text_corpus, content_transformer(replaceUnicode))
text_corpus <- tm_map(text_corpus, content_transformer(replaceNewLine))
text_corpus <- tm_map(text_corpus, content_transformer(replaceContraction))
text_corpus <- tm_map(text_corpus, content_transformer(replaceMisc))
text_corpus <- tm_map(text_corpus, content_transformer(replaceEmoticons))
text_corpus <- tm_map(text_corpus, content_transformer(replacePunctuation))
text_corpus <- tm_map(text_corpus, removeNumbers)
text_corpus <- tm_map(text_corpus, content_transformer(removeSingleWords))

text_corpus <- tm_map(text_corpus, removeWords, stopwords("en"))
text_corpus <- tm_map(text_corpus, removeWords, stopwords("spanish"))
text_corpus <- tm_map(text_corpus, removeWords, stopwords("german"))
rlog::log_info("Completed with removal of stopwords from the text.")

text_corpus <- tm_map(text_corpus, content_transformer(removeTextElongations))
rlog::log_info("Completed with removal of elongated words from the text.")

text_corpus <- tm_map(text_corpus, removeWhitespaces)
rlog::log_info("Completed textual data cleaning.")

## -----------------------------------------------------------
## inspect(text_corpus[1:100])

df_clean_tweets <- data.frame(text = sapply(text_corpus, as.character), stringsAsFactors = FALSE)
colnames(df_clean_tweets) <- c("clean_text")

## replace blanks with NA
df_clean_tweets <- df_clean_tweets %>% mutate_all(na_if, "")

## ----------------------------------------------------------
 
## view(updated_csv)

## appending as a column to csv file.
rlog::log_info("Creating Preprocessed CSV File.")
updated_csv <- cbind(data, df_clean_tweets)

# Remove entire row if any duplicates in clean text column
updated_csv <- updated_csv %>%
  filter(duplicated(clean_text) == FALSE)

updated_csv <- updated_csv %>% drop_na(clean_text)

write.csv(updated_csv, "/Users/twishisaran/Documents/Fall 2022 - CSUN /COMP 541 - Data Mining/Project/DisasterAnalysis/Training_Tweets.csv", append = FALSE)

## -----------------------------------------------------------
rlog::log_info("Pre processed and data cleaning completed. File saved.")
