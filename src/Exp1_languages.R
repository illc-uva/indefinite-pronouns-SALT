library(plyr)
library(dplyr)
library(ggplot2)
library(tidyr)
library(minpack.lm)

source("./Indefinites_functions.R")


####################################
####################################
# DATA
####################################
#Natural language data
####################################
# Import Haspelmath's data file: 1 = yes, 6=no, 9=no info. 
# Columns DET and PERSON added by Milica based on the data from Haspelmath's appendix A with 1 meaning that the IP has respectively a DET and PERSON version, and 0 that it doesn't.
# Column neg.frag added by Milica based on data collected from literature or from competent speakers: 1 corresponds to the IP being used in constructions in which it is interpreted as a negated existential (such as negative fragment answers), 6 to it not being used. These data are made available in an online Appendix.
Folder = "../data/"
langdata = read.csv(paste0(Folder, "languages_real_40_updated.csv"), header = TRUE)
langdata[langdata == 6] <-0 

# Subset to indefinite pronouns for persons.
langdata <- subset(langdata, PERSON == 1)

# Extract flavors for different items from Haspelmath's data based on our working assumptions
langdata = extract_flavors(langdata)

# Subset the data to relevant columns
relevant <- c("LANG", "ITEM", "skflavor", "suflavor", "nsflavor", "npiflavor", "fciflavor", "nqflavor")
df <- langdata[relevant]
df$type <- "natural"

# If generate = FALSE, we are importing already generated artificial languages from a csv file, if generate = TRUE, we are generating them from scratch
generate <- FALSE

####################################
#Artificial language data
####################################

# Generate a data frame with all logically possible items (in terms of which flavors they can take).
allpossibilities <- expand.grid(rep(list(0:1), 6))
colnames(allpossibilities) <- c("skflavor", "suflavor", "nsflavor", "npiflavor", "fciflavor", "nqflavor")

# Remove the one item that cannot take any of the flavors
allpossibilities = subset(allpossibilities, !(skflavor== 0 & suflavor ==0 & nsflavor ==0 & npiflavor == 0 & fciflavor == 0 & nqflavor ==  0))

# Generate fake languages and their items
fakefilename = paste0(Folder, "artificial_languages_exp1.csv")

if(generate) {
  fakelangdf = generate_languages(1, 10000, allpossibilities)
  fakelangdf$type <- "artificial"
  write.csv(fakelangdf, fakefilename, row.names=FALSE)
} else {
  fakelangdf <- read.csv(fakefilename)
}

# Bind natural and artificial languages data
df <-rbind(df,fakelangdf)

####################################
# Additional estimates that will be useful in later computations
####################################
# Prep a data frame (cf. function prep)
df = prep(df)

# Complexity of a language in terms of Haspelmath's features
# Import minimal descriptions (generated by Min-desc-algo.R script)
min.desc = read.csv2(paste0(Folder, "minimum-desc-indef.csv"), header = TRUE)
df <- merge(df, min.desc[,c("meaning", "complexity", "names.descriptions.")], by = c("meaning"))

####################################
# COMPUTE COMMUNICATIVE COST AND COMPLEXITY OF LANGUAGES
####################################
compcostfile <- paste0(Folder, "all_complexity_cost_exp1.csv")

if(generate) {
  allfinal <-compcostsyn(df)
  write.csv(allfinal, compcostfile, row.names=FALSE)
} else {
  allfinal <- read.csv(compcostfile)
}

####################################
# SYNONYMY MATCHING
####################################

# If generate = FALSE, we are importing already matched languages from a csv file, if generate = TRUE, we are doing the synonymy matching from scratch
generatesyn = FALSE

# Do synonymy matching
synfile = paste0(Folder, "syn_matched_exp1.csv")

if(generatesyn) {
  allfinal = synmatch(allfinal, "natural", "artificial")
  write.csv(allfinal, synfile, row.names=FALSE)
}else {
  allfinal <- read.csv(synfile)
}

# Check that means of synonymity indices in two groups are roughly the same
mean(subset(allfinal, type == "natural")$syn_index)
mean(subset(allfinal, type == "artificial")$syn_index)
