## Visualization
## ---------------------------------------

library(wordcloud)
library(data.table)
library(rJava)
library(RWeka)
library(SnowballC)
library(NLP)
library(ggplot2)
library(ggthemes)


setwd("/Users/twishisaran/Documents/Fall 2022 - CSUN /COMP 541 - Data Mining/Project/DisasterAnalysis")
## getting the pre processed data
## ---------------------------------------
clean_data <- read.csv("PreProcessed_Tweets.csv")

data.text <- iconv(clean_data$clean_text, to = "utf-8")
text_corpus <- Corpus(VectorSource(data.text))

## additional pre processing
## ---------------------------------------
text_corpus <- tm_map(
  text_corpus, removeWords,
  c(
    "hurricane", "ian", "fiona", "biden", "florida",
    "puerto", "rico", "president", "joe", "desantis"
  )
)


tokenization_tweets <- function(text) {
  NGramTokenizer(text, Weka_control(min = 2, max = 3))
}
tdm_Tweets <- TermDocumentMatrix(text_corpus, control = list(tokenize = tokenization_tweets))
trm_Freq <- rowSums(as.matrix(tdm_Tweets))
trm_Freq_Vector_Tweets <- as.list(trm_Freq)

tweets_df <- data.frame(unlist(trm_Freq_Vector_Tweets), stringsAsFactors = FALSE)
setDT(tweets_df, keep.rowname = TRUE)

setnames(tweets_df, 1, "term")
setnames(tweets_df, 2, "freq")

## view(tweets_df)
## -------------------------------------------------------------------------
## GG Plot
tweets_dt <- head(arrange(tweets_df, desc(freq)), n = 80)
rlog::log_info("Visualizing through a gg plot")


ggplot(data = tweets_dt, aes(x = reorder(term, freq), y = freq)) +
  geom_bar(stat = "identity", fill = "#94D7FF", colour = "#1B5274") +
  labs(title = "Occurance of terms ", subtitle = "(entire dataset is considered as a document)") +
  geom_label(aes(x = reorder(term, freq), y = freq, label = freq)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  coord_flip()


## --------------------------------------------------------------
## Word-cloud
rlog::log_info("Visualizing through a word cloud")

wordcloud(
  words = tweets_df$term, freq = tweets_df$freq, min.freq = 10,
  max.words = Inf, random.order = FALSE, rot.per = 0.35,
  width = 1000, height = 1000,
  colors = brewer.pal(6, "Dark2")
)


## --------------------------------------------------------------
## Correlation of top freq words
rlog::log_info("Correlations between words and the document matrix")


findAssocs(tdm_Tweets, "power", 0.10)

findAssocs(tdm_Tweets, "help", 0.10)

findAssocs(tdm_Tweets, "damage", 0.20)

findAssocs(tdm_Tweets, "relief", 0.10)

findAssocs(tdm_Tweets, "people", 0.10)

