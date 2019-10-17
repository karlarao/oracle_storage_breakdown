# by Karl Arao
# 
# Prereq: 
# 1) R studio
# 2) XML, sqldf, XLConnect packages
# 
# HOWTO: 
# 1) create a new folder -> copy this R script and the html files
# 2) on R studio open the R script -> CTRL-A -> click Run -> check the .xls output



# #set_java_home: just do this on windows environments or when java is not on current path 
# set_java_home <- function() {
#   Sys.setenv(JAVA_HOME="C:/Users/A474664/Documents/work_tools/sqldeveloper-18.2.0.183.1748-x64/sqldeveloper/jdk")
#   # Sys.setenv(JAVA_HOME="C:/Program Files (x86)/Java/jre8")
#   options(java.parameters = c("-XX:+UseConcMarkSweepGC", "-Xmx4096m")  )
#   library(rJava)
#   library(XLConnect)
#   system("java -version")
#   Sys.getenv()
# }
# set_java_home()


# set_current_directory()
# use inside the script to set the current working directory

# http://stackoverflow.com/a/36777602/4285039
csf <- function() {
  # http://stackoverflow.com/a/32016824/2292993
  cmdArgs = commandArgs(trailingOnly = FALSE)
  needle = "--file="
  match = grep(needle, cmdArgs)
  if (length(match) > 0) {
    # Rscript via command line
    return(normalizePath(sub(needle, "", cmdArgs[match])))
  } else {
    ls_vars = ls(sys.frames()[[1]])
    if ("fileName" %in% ls_vars) {
      # Source'd via RStudio
      return(normalizePath(sys.frames()[[1]]$fileName))
    } else {
      if (!is.null(sys.frames()[[1]]$ofile)) {
        # Source'd via R console
        return(normalizePath(sys.frames()[[1]]$ofile))
      } else {
        # RStudio Run Selection
        # http://stackoverflow.com/a/35842176/2292993
        return(normalizePath(rstudioapi::getActiveDocumentContext()$path))
      }
    }
  }
}

set_current_directory <- function() {
  source_file <- csf()
  
  # fix path http://stackoverflow.com/posts/26488342/revisions
  source_file <- gsub("\\\\","/",source_file)
  
  # just get directory path http://stackoverflow.com/posts/15073919/revisions
  current_dir <- gsub("(.*\\/)([^.]+)(\\.[[:alnum:]]+$)", "\\1", source_file)
  setwd(current_dir)
  getwd()
}

# my function to set current directory
set_current_directory()


# packages
library(XML)
library(sqldf)
library(XLConnect)

# read file
html_files <- Sys.glob("*html")


# parse data
data_wb <- data.frame()
for (i in html_files) {
  
  pdb_name <- strsplit(i,"-")[[1]][3]
  cat(paste0(i , "---", pdb_name),"\n")
  
  # read in HTML data
  tbls_xml <- readHTMLTable(i)
  tbl_df <- as.data.frame(tbls_xml)
  
  # sql 
  sqldata <- sqldf("select null pdb, a.* from tbl_df a")
  sqldata$pdb <- pdb_name
  
  # fix headers
  colnames(sqldata) <- c("pdb","dbid","name","file_type","bytes","gb","display")
  
  # bind rows
  data_wb <- rbind(data_wb,sqldata)
}
data_wb


# create or append to file
excel <- Sys.glob("db_size.xls")
if(length(excel) == 0) {
  # Setup a new spreadsheet
  wb2 <- loadWorkbook("db_size.xls", create = TRUE)
  # Create a sheet called data
  createSheet(wb2, name = "data")
  writeWorksheet (wb2, data=data_wb, sheet="data", header = TRUE)
  # Save the workbook
  saveWorkbook(wb2, file = "db_size.xls")
} else {
  print("excel data exist")
}




# sqldata queries
#
sqldf("select sum(gb) from data_wb where file_type != 'Total' and pdb != 'ROOT'")
