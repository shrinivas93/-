sink(tempfile())
library(NLP)
library(tm)
library(RColorBrewer)
library(wordcloud)
library(wordcloud2)
library(sentiment)
library(DBI)
library(RMySQL)

output = "D:/wordclouds/"

db =
  dbConnect(
    MySQL(),
    user = "root",
    password = "root",
    dbname = "semicolon",
    host = "localhost"
  )
on.exit(dbDisconnect(db))
dt = dbReadTable(db, 
                 'comments')

removeURL = function(x)
  gsub("http[^[:space:]]*",  "", x)
removeNumPunct = function(x)
  gsub("[^[:alpha:][:space:]]*",  "", x)

myStopwords = c(stopwords('english'), "test", "can")
myStopwords = setdiff(myStopwords, "not")

myCorpus = Corpus(VectorSource(dt$comment))
myCorpus = tm_map(myCorpus, content_transformer(tolower))
myCorpus = tm_map(myCorpus, content_transformer(removeURL))
myCorpus = tm_map(myCorpus, content_transformer(removeNumPunct))
myCorpus = tm_map(myCorpus, stripWhitespace)
myCorpus = tm_map(myCorpus, removeWords, myStopwords)

tdm =
  TermDocumentMatrix(myCorpus, control = list(wordLengths = c(2, Inf)))
m = as.matrix(tdm)
word.freq = sort(rowSums(m), decreasing = T)

timestamp = format(Sys.time(), "%d%m%Y_%H%M%S")
jpeg(
  paste(output ,timestamp, ".jpeg"),
  width = 1920,
  height = 1920,
  res = 400,
  quality = 70
)
wordcloud(
  words = names(word.freq),
  freq = word.freq,
  min.freq = 3,
  random.order = FALSE,
  rot.per=0.1,
  colors = brewer.pal(8, "Dark2")
)

dev.off()

class_pol = classify_polarity(dt$comment , algorithm = 'naive bayes')
polarity = class_pol[, 4]

dt$score = 0
dt$score[polarity == "positive"] = (1)
dt$score[polarity == "negative"] = (-1)

dbWriteTable(
  conn = db,
  name = 'sentiment',
  value = as.data.frame(dt),
  overwrite = TRUE
)
sink()