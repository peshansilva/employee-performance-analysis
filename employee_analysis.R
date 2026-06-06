# ============================================================
# IT3011 - Group Assignment
# Statement:
# Employees who receive regular feedback perform better
# than those who do not
# ============================================================

# -------------------------------
# 1. Load packages
# -------------------------------
library(dplyr)
library(ggplot2)
library(readr)
library(caret)

# -------------------------------
# 2. Load datasets
# -------------------------------
emp <- read_csv("Employee.csv")
perf <- read_csv("PerformanceRating.csv")

df <- inner_join(perf, emp, by = "EmployeeID")

# -------------------------------
# 3. Data preparation
# -------------------------------
df <- df %>%
  mutate(
    FeedbackGroup = ifelse(TrainingOpportunitiesWithinYear >= 2,
                           "Regular Feedback",
                           "No Regular Feedback"),
    
    HighPerformer = ifelse(ManagerRating >= 4, "High", "Low"),
    
    ReviewDate = as.Date(ReviewDate, format = "%m/%d/%Y"),
    Year = as.numeric(format(ReviewDate, "%Y"))
  )

df$FeedbackGroup <- factor(df$FeedbackGroup,
                           levels = c("No Regular Feedback", "Regular Feedback"))

df$HighPerformer <- factor(df$HighPerformer,
                           levels = c("Low", "High"))

df$TrainFactor <- factor(df$TrainingOpportunitiesWithinYear)

# -------------------------------
# 4. Descriptive analytics
# -------------------------------
desc_stats <- df %>%
  group_by(FeedbackGroup) %>%
  summarise(
    Count = n(),
    Mean = mean(ManagerRating, na.rm = TRUE),
    SD = sd(ManagerRating, na.rm = TRUE)
  )

print(desc_stats)

# -------------------------------
# 5. Visualisations (WITH COLOURS)
# -------------------------------

# Boxplot
p1 <- ggplot(df, aes(x = FeedbackGroup, y = ManagerRating, fill = FeedbackGroup)) +
  geom_boxplot() +
  scale_fill_manual(values = c(
    "No Regular Feedback" = "#A7C7E7",
    "Regular Feedback" = "#1E3A8A"
  )) +
  labs(
    title = "Manager Rating by Feedback Group",
    x = "Feedback Group",
    y = "Manager Rating"
  ) +
  theme_minimal()

ggsave("plot1_boxplot.png", p1, width = 7, height = 5)

# Bar chart
avg_rating <- df %>%
  group_by(FeedbackGroup) %>%
  summarise(MeanRating = mean(ManagerRating, na.rm = TRUE))

p2 <- ggplot(avg_rating, aes(x = FeedbackGroup, y = MeanRating, fill = FeedbackGroup)) +
  geom_col(width = 0.5) +
  scale_fill_manual(values = c(
    "No Regular Feedback" = "#A7C7E7",
    "Regular Feedback" = "#1E3A8A"
  )) +
  labs(
    title = "Average Manager Rating by Feedback Group",
    x = "Feedback Group",
    y = "Average Manager Rating"
  ) +
  theme_minimal()

ggsave("plot2_bar.png", p2, width = 7, height = 5)

# -------------------------------
# 6. Time Series
# -------------------------------
ts_data <- df %>%
  group_by(Year, FeedbackGroup) %>%
  summarise(
    MeanRating = mean(ManagerRating, na.rm = TRUE),
    .groups = "drop"
  )

p_ts <- ggplot(ts_data, aes(x = Year, y = MeanRating, color = FeedbackGroup)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_color_manual(values = c(
    "No Regular Feedback" = "#A7C7E7",
    "Regular Feedback" = "#1E3A8A"
  )) +
  labs(
    title = "Manager Rating Over Time by Feedback Group",
    x = "Year",
    y = "Average Manager Rating"
  ) +
  theme_minimal()

ggsave("plot3_timeseries.png", p_ts, width = 8, height = 5)

# -------------------------------
# 7. Inferential analytics
# -------------------------------

# t-test
group1 <- df %>% filter(FeedbackGroup == "Regular Feedback") %>% pull(ManagerRating)
group2 <- df %>% filter(FeedbackGroup == "No Regular Feedback") %>% pull(ManagerRating)

t_test <- t.test(group1, group2)
print(t_test)

# ANOVA
anova_result <- aov(ManagerRating ~ TrainFactor, data = df)
print(summary(anova_result))

# Chi-square
table_data <- table(df$FeedbackGroup, df$HighPerformer)
chi_test <- chisq.test(table_data)
print(chi_test)

# Correlation
cor_test <- cor.test(df$TrainingOpportunitiesWithinYear, df$ManagerRating)
print(cor_test)

# -------------------------------
# 8. Predictive analytics
# -------------------------------

# Linear regression
lm_model <- lm(
  ManagerRating ~ TrainingOpportunitiesWithinYear +
    TrainingOpportunitiesTaken +
    SelfRating +
    JobSatisfaction +
    WorkLifeBalance +
    Age +
    YearsAtCompany,
  data = df
)

print(summary(lm_model))

# Logistic regression
df$HighBin <- ifelse(df$HighPerformer == "High", 1, 0)

log_model <- glm(
  HighBin ~ TrainingOpportunitiesWithinYear +
    TrainingOpportunitiesTaken +
    SelfRating +
    JobSatisfaction +
    WorkLifeBalance +
    Age +
    YearsAtCompany,
  data = df,
  family = binomial
)

print(summary(log_model))

# Accuracy
df$Pred <- ifelse(predict(log_model, type = "response") > 0.5, "High", "Low")
df$Pred <- factor(df$Pred, levels = c("Low", "High"))

cm <- confusionMatrix(df$Pred, df$HighPerformer)
print(cm$overall["Accuracy"])

# -------------------------------
# 9. Final conclusion
# -------------------------------
cat("\nFinal Conclusion:\n")
cat("There is no strong statistical evidence that regular feedback improves performance.\n")