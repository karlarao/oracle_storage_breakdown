
set_current_directory()

# packages
library(XML)
library(sqldf)

# read file
url <- "storage_03_db_size-cdbdvlx11-ROOT-1.html"
pdb_name <- strsplit(url,"-")[[1]][3]

# read in HTML data
tbls_xml <- readHTMLTable(url)
tbl_df <- as.data.frame(tbls_xml)

# sql 
sqldata <- sqldf("select null region, a.* from tbl_df a")
sqldata$region <- pdb_name

colnames(sqldata) <- c("region","dbid","name","file_type","bytes","gb","display")
sqldata
sqldf("select sum(gb) from sqldata where file_type != 'Total'")
