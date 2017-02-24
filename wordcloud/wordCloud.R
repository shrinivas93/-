sink(tempfile())
suppressMessages(library("tm"))
suppressMessages(library("NLP"))
suppressMessages(library("SnowballC"))
suppressMessages(library("wordcloud"))
suppressMessages(library("RColorBrewer"))
suppressMessages(library("RMySQL"))
suppressMessages(library("DBI"))

output = "D:/rscripts/wordcloud/output/"

db = dbConnect(
  MySQL(),
  user='root',
  password='root',
  dbname='semicolon',
  host='localhost'
)
data = dbReadTable(db,'comments')

docs <- Corpus(VectorSource(data$comment))

toSpace <- content_transformer(function (x , pattern ) gsub(pattern, " ", x))
docs <- tm_map(docs, toSpace, "/")
docs <- tm_map(docs, toSpace, "@")
docs <- tm_map(docs, toSpace, "\\|")

docs <- tm_map(docs, content_transformer(tolower))
docs <- tm_map(docs, removeNumbers)
myStopWords = c(stopwords("english"), c("test"))
myStopWords = setdiff(myStopWords,"not")
docs <- tm_map(docs, removeWords, myStopWords)
docs <- tm_map(docs, removePunctuation)
docs <- tm_map(docs, stripWhitespace)
#docs <- tm_map(docs, stemDocument)

dtm <- TermDocumentMatrix(docs)
m <- as.matrix(dtm)
v <- sort(rowSums(m),decreasing=TRUE)
d <- data.frame(word = names(v),freq=v)
#head(d, 10)

timestamp = format(Sys.time(), "%d%m%Y_%H%M%S")
jpeg(
  filename=paste(output ,timestamp, ".jpeg"),
  width=1920,
  height=1920,
  res = 600,
  quality=50
)
#set.seed(42)
suppressWarnings(
  wordcloud(
    words = d$word,
    freq = d$freq,
    min.freq = 1,
    max.words=Inf,
    random.order=FALSE,
    rot.per=0.1,
    colors=brewer.pal(8, "Dark2")
  )
)
dev.off()
sink()