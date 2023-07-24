# Get training data.

import pandas as pd
import numpy as np
import nltk

nltk.download('punkt')
nltk.download('stopwords')
# from nltk import word_tokenize
from nltk.corpus import stopwords
from sklearn.model_selection import train_test_split
import string
import matplotlib.pyplot as plt


def text_cleaning(text):
    remove_punctuation = [char for char in text if char not in string.punctuation]
    remove_punctuation = ''.join(remove_punctuation)
    return [word for word in remove_punctuation.split()
            if word.lower() not in stopwords.words('english')]


##-----------------------------------------------------------------------------

training_data = pd.read_csv(r'/Users/twishisaran/Documents/Fall 2022 - CSUN /COMP 541 - Data Mining/Project/DisasterAnalysis/Training_Tweets.csv',
                            usecols=['label', 'clean_text'])  ## put the training dataset path here

crawled_data_preprocessed = pd.read_csv('/Users/twishisaran/Documents/Fall 2022 - CSUN /COMP 541 - Data Mining/Project/DisasterAnalysis/PreProcessed_Tweets.csv',
                                        usecols=['clean_text'])  ## put the crawled dataset path here

 
training_data.iloc[:,1].apply(text_cleaning) ##applying cleaning (last column)


##-----------------------------------------------------------------------------
## declaring training and testing data

X = training_data.clean_text
y = training_data.label
yy = crawled_data_preprocessed.clean_text
 
##-----------------------------------------------------------------------------
## Applying Multinomial Naive to training data and labelling the collected tweets
from sklearn.pipeline import Pipeline
from sklearn.naive_bayes import MultinomialNB
from sklearn.feature_extraction.text import CountVectorizer, TfidfTransformer
from sklearn.metrics import confusion_matrix, accuracy_score, precision_score ,classification_report, ConfusionMatrixDisplay

naivebayes = Pipeline([('vect', CountVectorizer()),
                       ('tfidf', TfidfTransformer()),
                       ('clf', MultinomialNB()),
                       ])
naivebayes.fit(X, y) ##training the model with training dataset and its labels
y_predict_mnb = naivebayes.predict(yy) ## predicting labels of test dataset
y_df = pd.DataFrame(y_predict_mnb)

# combining clean_text in yy and its corresponding label in y_df and creating new csv file(labelled_dataset.csv)
result_df = pd.concat([yy, y_df], axis=1)
result_df.set_axis(["clean_text", "label"], axis=1, inplace=True)
result_df.to_csv('/Users/twishisaran/Documents/Fall 2022 - CSUN /COMP 541 - Data Mining/Project/DisasterAnalysis/labelled_dataset.csv',index=False)

## plotting the highest occurring classes
labels_occurs = result_df.groupby(['label']).size()

import seaborn as sns
sns.set_style("whitegrid") 
sns.set_context("notebook")
labels_occurs.plot(kind="barh")
plt.title("Occurances of each Label")
plt.xlabel("Number of Tweets")
plt.ylabel("Class Label")

##-----------------------------------------------------------------------------
## Semi-supervised Method 1
#merging the datasets(training dataset and newly labelled dataset) to create a new dataset
df_final = result_df.append(training_data, ignore_index=True)
df_final.to_csv('/Users/twishisaran/Documents/Fall 2022 - CSUN /COMP 541 - Data Mining/Project/DisasterAnalysis/final_dataset.csv',index=False)

df_final.iloc[:,0].apply(text_cleaning) ##applying cleaning 

XX = df_final.clean_text
YY = df_final.label

#splitting the combined dataset into training and testing subsets and training the model in a semi-supervised way
XX_train, XX_test, YY_train, YY_test = train_test_split(XX, YY , test_size = 0.2, random_state = 42)

naivebayes.fit(XX_train, YY_train) 

YY_predict_mnb = naivebayes.predict(XX_test)

## printing the accuracy and performance for semi-supervised approach
print(f'Accuracy score is: { accuracy_score(YY_predict_mnb ,YY_test )}') 
print( 'Classification Performance : \n',classification_report(YY_predict_mnb,YY_test ) ) 
 
cf_matrix = confusion_matrix(YY_test, YY_predict_mnb, labels=naivebayes.classes_)
disp = ConfusionMatrixDisplay(confusion_matrix=cf_matrix, display_labels=naivebayes.classes_)
disp = disp.plot(cmap=plt.cm.Blues,values_format='g')
plt.show()
 
##----------------------------------------------------------------------------------------------------------------------------
## Supervised Method 2
## utilizing the fnal_dataset to train naive bayes and label random tweets (a supervised approach)

# Get the final labelled data
XX = training_data.clean_text
YY = training_data.label

XX_train, XX_test, YY_train, YY_test = train_test_split(XX, YY ,test_size = 0.2, random_state = 42)
 

# Create dictionary and transform to feature vectors. 
count_vector = CountVectorizer()
X_train_counts = count_vector.fit_transform(XX_train)
 

# TF-IDF vectorize. 
tfidf_transformer = TfidfTransformer()
X_train_tfidf = tfidf_transformer.fit_transform(X_train_counts) 

# Create model(naive bayes) and training. 
clf = MultinomialNB().fit(X_train_tfidf, YY_train)


X_new_counts = count_vector.transform(XX_test)
X_new_tfidf = tfidf_transformer.transform(X_new_counts)

# Execute prediction(classification).
predicted = clf.predict(X_new_tfidf)


## printing the accuracy and performance for supervised approach
print(f'Accuracy score for supervised learning is: { accuracy_score(predicted ,YY_test )}') 
print( 'Classification Performance for supervised learning: \n',
      classification_report(predicted,YY_test ) ) 
 
cf_matrix = confusion_matrix(YY_test, predicted, labels=clf.classes_)
disp = ConfusionMatrixDisplay(confusion_matrix=cf_matrix, display_labels=clf.classes_)
disp = disp.plot(cmap=plt.cm.Blues,values_format='g')
plt.show()
  
#------------------------------------------------------------------------------
# Testing the supervised classifier on some random tweets

docs_new = ['L.A. hits $1-billion earthquake milestone according to Los Angeles Times', 
            'the Napa Food Bank limited nonperishable food items; Volunteers require funding',
            "United states may have higher death rate than last year"]

X_new_counts = count_vector.transform(docs_new)
X_new_tfidf = tfidf_transformer.transform(X_new_counts)

# Execute prediction(classification).
predicted = clf.predict(X_new_tfidf)

# Show predicted data.
for doc, category in zip(docs_new, predicted):
    print("{0} => {1}".format(doc, category))
    

    