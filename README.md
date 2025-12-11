# ml-birdwatching
Exploration of the problem of predicting bird observations based on the weather and date

# Files
## data/ebird_first.R
R code for processing data from the raw ebird observation and sampling data.

## birds_ml.ipynb
The main Jupyter notebook for data processing and model training/evaluation. Requires ebird_first.R to be run beforehand.

Raw data files were not included due to size. The data files included represent the result of running ebird_first.R on raw data downloaded from eBird.

## randomforest.pkl
A file containing the serialized forest model used in feature importance. Its generation is shown at the end of birds_ml.ipynb

## requirements.txt
Lists required python packages for the jupyter notebook to run
