# User-Based-Collaborative-Movie-Recommendation-System

An interactive Shiny web application that provides personalized movie recommendations using **User-Based Collaborative Filtering (UBCF)** and **Item-Based Collaborative Filtering (IBCF)**. Users can also rate movies to improve recommendation quality.

---

## 📌 Features

- 🔍 **Select a User** from the MovieLense dataset.
- ⚙️ **Choose Algorithm**: UBCF or IBCF.
- 🎯 **Customize Number of Recommendations**.
- ⭐ **Rate Movies** dynamically within the app.
- 📊 **Visualize Recommendations** as tables and bar plots.
- 🗂️ **Create Multiple Recommendation Tabs** with close functionality.
- 🌐 Built using R, Shiny, and recommenderlab.

---

## 🧠 How It Works

### 1. **User-Based Collaborative Filtering (UBCF)**
- Finds users with similar rating patterns.
- Recommends movies liked by similar users.

### 2. **Item-Based Collaborative Filtering (IBCF)**
- Finds items that are similar based on user ratings.
- Recommends movies similar to the ones the user liked.

---

## 🗃️ Dataset

- Uses the `MovieLense` dataset from the `recommenderlab` package.
- Filters to include users with >50 ratings and movies with >100 ratings for quality.

---

## 🚀 Getting Started

### 📦 Requirements

Install these R packages:

install.packages(c("shiny", "recommenderlab", "Matrix", "dplyr", "ggplot2"))

## To Run the Code on RStudio:

shiny::runApp("app_directory")

Replace "app_directory" with the path to your app.R file.
