library(dplyr)
library(reshape2)

features <- tbl_df(read.table("./data/features.txt", stringsAsFactors = FALSE))
colnames(features) <- c("no", "feature_name")
feature_names <- features$feature_name

# indices of features we want to select
features_wanted <- grep(paste(c("mean", "std"), collapse = "|"), feature_names, ignore.case = FALSE)
# names of the features
features_wanted_names <- feature_names[features_wanted]

# clean up the feature names
features_wanted_names <- gsub("-mean", "Mean", features_wanted_names)
features_wanted_names <- gsub("-std", "Std", features_wanted_names)
features_wanted_names <- gsub("[()-]", "", features_wanted_names)

# read the training data
train_df <- tbl_df(read.table("./data/train/X_train.txt", stringsAsFactors = FALSE))
train_df <- select(train_df, features_wanted)

# update the column names in the data set
colnames(train_df) <- features_wanted_names

# add activity labels to the training data
activity_labels <- tbl_df(read.table("./data/activity_labels.txt", stringsAsFactors = FALSE))
training_labels <- tbl_df(read.table("./data/train/y_train.txt", stringsAsFactors = FALSE))

colnames(activity_labels) <- c("activity_id", "activity")
train_df <- tbl_df(cbind(training_labels, train_df))

# add subject info to the training data
subjects <- tbl_df(read.table("./data/train/subject_train.txt", stringsAsFactors = FALSE))
colnames(subjects) <- c("subject_id")
train_df <- tbl_df(cbind(subjects$subject_id, train_df))

colnames(train_df)[1] <- "subjectId"
colnames(train_df)[2] <- "activity"

# read the test data
test_df <- tbl_df(read.table("./data/test/X_test.txt", stringsAsFactors = FALSE))
test_df <- select(test_df, features_wanted)
colnames(test_df) <- features_wanted_names

# add subject info
test_subjects <- tbl_df(read.table("./data/test/subject_test.txt", stringsAsFactors = FALSE))
test_training_labels <- tbl_df(read.table("./data/test/y_test.txt", stringsAsFactors = FALSE))

colnames(test_subjects) <- c("subject_id")

test_df <- tbl_df(cbind(test_training_labels, test_df))
test_df <- tbl_df(cbind(test_subjects$subject_id, test_df))

colnames(test_df)[1] <- "subjectId"
colnames(test_df)[2] <- "activity"

# merge test and train data sets
all_data <- tbl_df(rbind(train_df, test_df))

# subjects and activities as factors
all_data$subjectId <- as.factor(all_data$subjectId)
all_data$activity <- factor(all_data$activity, levels = activity_labels$activity_id, labels = activity_labels$activity)

melted <- tbl_df(melt(all_data, id = c("subjectId", "activity")))
data_mean <- tbl_df(dcast(melted, subjectId + activity ~ variable, mean))

# descriptive column names
names(data_mean) <- gsub("^t", "time", names(data_mean))
names(data_mean) <- gsub("^f", "freq", names(data_mean))
names(data_mean) <- gsub("BodyBody", "Body", names(data_mean))
names(data_mean) <- gsub("Mag", "Magnitude", names(data_mean))

# write tidy data to file
write.table(data_mean, file = "./tidy.txt", col.names = TRUE, row.names = FALSE,  quote = FALSE)

data_mean

rmarkdown::render("./run_analysis.Rmd")