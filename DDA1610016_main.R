# Load libraries
library("MASS")
library("car")
library("stringr")
library(ggplot2)
library(reshape2)

# Load car data
carmileage<-read.csv("E:/IIITB/Course3/SubmittedAssignmentLinearRegression/carMPG.csv")

########Checkpoint 1############
# Business and data understanding
#---------------------------------

# Business objective: To find estimated car mileage based on car features

# Business constraints:
# The model should not contain more than 5 variables.
# According to the business needs, set the VIF to 2. 
# The model should be highly predictive in nature i.e it should show 80% (R squared) of accuracy.

# Data understanding : This data set contains 398 observations with data of various cars
# The features/attributes which describe the cars in the dataset are :
# 1. Mpg - Numeric and continous
# 2. Cylinders - Numeric and descrete
# 3. Displacement - Numeric and continuous
# 4. Horsepower - Numeric and continuous
# 5. Weight - Numeric and continuous
# 6. Acceleration - Numeric and continuous
# 7. Model year - Numeric and descrete
# 8. Origin - Numeric and descrete
# 9. Car name - String and descrete

# Check for NA values
length(grep("TRUE",is.na(carmileage))) #No NA values found

# Check the types of various variables
str(carmileage)

########Checkpoint 2############
# Data preparation and cleansing
#-------------------------------

# Variable formatting #

# Changing Cylinders, Origin variables to factors
carmileage$Cylinders<-as.factor(carmileage$Cylinders) 
carmileage$Origin<-as.factor(carmileage$Origin)

# Changing Horsepower to numeric
carmileage$Horsepower<-as.numeric(carmileage$Horsepower)

# Verifying structure
str(carmileage)

# Data cleaning #

# Outlier verification
boxplot.stats(carmileage$Weight) #No outlier
boxplot.stats(carmileage$Horsepower) #No outlier
boxplot.stats(carmileage$Displacement) #No outlier
boxplot.stats(carmileage$Acceleration) #7 outliers found

# Outlier treatment of Acceleration variable:
# Higher values to be capped at Upper hinge + 1.5X IQR
# Lower values to be capped at Lower hinge - 1.5X IQR

LHinge<-quantile(carmileage$Acceleration,prob=0.25)
UHinge<-quantile(carmileage$Acceleration,prob=0.75)

IQR<-UHinge-LHinge
carmileage$Acceleration<-ifelse(carmileage$Acceleration<LHinge-1.5*IQR,LHinge-1.5*IQR,
                                ifelse(carmileage$Acceleration>UHinge+1.5*IQR,UHinge+1.5*IQR,carmileage$Acceleration))
# Variable Transformation #

# Extracting feature car company name from Car_Name
carmileage$carCompany<-gsub(" .*$","",carmileage$Car_Name)


# Standardizing carCompany names
carmileage$carCompany<-ifelse(carmileage$carCompany=="chevy","chevrolet",
                       ifelse(carmileage$carCompany=="toyouta","toyota",
                       ifelse(carmileage$carCompany=="maxda","mazda",
                       ifelse(carmileage$carCompany=="chevroelt","chevrolet",
                       ifelse(carmileage$carCompany=="vw" | carmileage$carCompany=="vokswagen","volkswagen",
                       ifelse(carmileage$carCompany=="mercedes-benz","mercedes",carmileage$carCompany))))))
carmileage$carCompany<-as.factor(carmileage$carCompany)

# Binning of model year 
# Model year is binned into these ranges:
# 1. 2005orEarlier
# 2. Between2006-2008
# 3. Between2009-2012
# 4. 2013orLater
carmileage$Model_year<-as.integer(carmileage$Model_year)
carmileage$carModelBin<-ifelse(carmileage$Model_year<=2005,"2005orEarlier",
                               ifelse(carmileage$Model_year>=2006 & carmileage$Model_year<=2008,"Between2006-2008",
                                      ifelse(carmileage$Model_year>=2009 & carmileage$Model_year<=2012,"Between2009-2012",
                                             ifelse(carmileage$Model_year>=2013,"2013orLater",""))))
carmileage$carModelBin<-as.factor(carmileage$carModelBin)
levels(carmileage$carModelBin)

# Creating dummy variables for carCompany
dummy_comp <- data.frame(model.matrix( ~carCompany, data = carmileage))
dummy_comp<-dummy_comp[,-1]

# Creating dummy variables for Cylinders
dummy_cyl <- data.frame(model.matrix( ~Cylinders, data = carmileage))
dummy_cyl<-dummy_cyl[,-1]

# Creating dummy variables for Model_year
dummy_myear <- data.frame(model.matrix( ~carModelBin, data = carmileage))
dummy_myear<-dummy_myear[,-1]

# Creating dummy variables for Origin
dummy_orig <- data.frame(model.matrix( ~Origin, data = carmileage))
dummy_orig<-dummy_orig[,-1]

# Putting all relevant variables in one final data frame for modelling process
carmileage.final<-cbind(carmileage[,c(1,3:6)],dummy_cyl,dummy_myear,dummy_orig,dummy_comp)

# Creating training and testing data sets
# ---------------------------------------
 
# Divide data in 70:30 ratio
set.seed(101)
indices= sample(1:nrow(carmileage.final), 0.7*nrow(carmileage.final))

carmileage.train=carmileage.final[indices,]
carmileage.test = carmileage.final[-indices,]

########Checkpoint 3############

# Modelling process
#--------------------
# Constraints:
# The model should not contain more than 5 variables.
# According to the business needs, set the VIF to 2. 
# The model should be highly predictive in nature i.e it should show 80% (R squared) of accuracy.

car.Model1<-lm(MPG ~ .,data=carmileage.train)

summary(car.Model1)

step <- stepAIC(car.Model1, direction="both")

step

# Resulting formula
car.Model2<-lm(formula = MPG ~ Weight + Acceleration + Cylinders4 + Cylinders5 + 
                 Cylinders6 + Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                 carModelBinBetween2009.2012 + carCompanycadillac + carCompanydatsun + 
                 carCompanyfiat + carCompanyhonda + carCompanymazda + carCompanymercedes + 
                 carCompanyoldsmobile + carCompanyplymouth + carCompanypontiac + 
                 carCompanyrenault + carCompanytriumph + carCompanyvolkswagen, 
               data = carmileage.train)

summary(car.Model2) #R-squared :0.8598
vif(car.Model2)

# Removing carCompanymercedes p-value 0.15309
car.Model3<-lm(formula = MPG ~ Weight + Acceleration + Cylinders4 + Cylinders5 + 
                 Cylinders6 + Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                 carModelBinBetween2009.2012 + carCompanycadillac + carCompanydatsun + 
                 carCompanyfiat + carCompanyhonda + carCompanymazda + 
                 carCompanyoldsmobile + carCompanyplymouth + carCompanypontiac + 
                 carCompanyrenault + carCompanytriumph + carCompanyvolkswagen, 
               data = carmileage.train)

summary(car.Model3) #R-squared :0.8592
vif(car.Model3)

#Removing carCompanyoldsmobile p-value 0.14642
car.Model4<-lm(formula = MPG ~ Weight + Acceleration + Cylinders4 + Cylinders5 + 
                 Cylinders6 + Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                 carModelBinBetween2009.2012 + carCompanycadillac + carCompanydatsun + 
                 carCompanyfiat + carCompanyhonda + carCompanymazda + 
                 carCompanyplymouth + carCompanypontiac + 
                 carCompanyrenault + carCompanytriumph + carCompanyvolkswagen, 
               data = carmileage.train)

summary(car.Model4) #R-squared :0.8586
vif(car.Model4)

#Removing carCompanytriumph p-value 0.13898
car.Model5<-lm(formula = MPG ~ Weight + Acceleration + Cylinders4 + Cylinders5 + 
                 Cylinders6 + Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                 carModelBinBetween2009.2012 + carCompanycadillac + carCompanydatsun + 
                 carCompanyfiat + carCompanyhonda + carCompanymazda + 
                 carCompanyplymouth + carCompanypontiac + 
                 carCompanyrenault + carCompanyvolkswagen, 
               data = carmileage.train)

summary(car.Model5) #R-squared :0.8579
vif(car.Model5)


#Removing carCompanyvolkswagen p-value: 0.14905
car.Model6<-lm(formula = MPG ~ Weight + Acceleration + Cylinders4 + Cylinders5 + 
                 Cylinders6 + Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                 carModelBinBetween2009.2012 + carCompanycadillac + carCompanydatsun + 
                 carCompanyfiat + carCompanyhonda + carCompanymazda + 
                 carCompanyplymouth + carCompanypontiac + 
                 carCompanyrenault, 
               data = carmileage.train)

summary(car.Model6) #R-squared :0.8574
vif(car.Model6)

#Removing carCompanyplymouth p-value: 0.14443
car.Model7<-lm(formula = MPG ~ Weight + Acceleration + Cylinders4 + Cylinders5 + 
                 Cylinders6 + Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                 carModelBinBetween2009.2012 + carCompanycadillac + carCompanydatsun + 
                 carCompanyfiat + carCompanyhonda + carCompanymazda + 
                 carCompanypontiac + 
                 carCompanyrenault, 
               data = carmileage.train)

summary(car.Model7) #R-squared :0.8567
vif(car.Model7)

#Removing carCompanyfiat p-value: 0.11377
car.Model8<-lm(formula = MPG ~ Weight + Acceleration + Cylinders4 + Cylinders5 + 
                 Cylinders6 + Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                 carModelBinBetween2009.2012 + carCompanycadillac + carCompanydatsun + 
                 carCompanyhonda + carCompanymazda + 
                 carCompanypontiac + 
                 carCompanyrenault, 
               data = carmileage.train)

summary(car.Model8) #R-squared :0.8559
vif(car.Model8)

#Removing carCompanyhonda p-value=0.13583 
car.Model9<-lm(formula = MPG ~ Weight + Acceleration + Cylinders4 + Cylinders5 + 
                 Cylinders6 + Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                 carModelBinBetween2009.2012 + carCompanycadillac + carCompanydatsun + 
                 carCompanymazda + carCompanypontiac + carCompanyrenault, 
               data = carmileage.train)

summary(car.Model9) #R-squared :0.8552
vif(car.Model9)

#Removing carCompanyrenault p-value 0.11545
car.Model10<-lm(formula = MPG ~ Weight + Acceleration + Cylinders4 + Cylinders5 + 
                  Cylinders6 + Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                  carModelBinBetween2009.2012 + carCompanycadillac + carCompanydatsun + 
                  carCompanymazda + carCompanypontiac, 
                data = carmileage.train)

summary(car.Model10) #R-squared :0.8544
vif(car.Model10)

#Removing carCompanymazda p-value 0.09284
car.Model11<-lm(formula = MPG ~ Weight + Acceleration + Cylinders4 + Cylinders5 + 
                  Cylinders6 + Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                  carModelBinBetween2009.2012 + carCompanycadillac + carCompanydatsun + 
                  carCompanypontiac, 
                data = carmileage.train)

summary(car.Model11) #R-squared :0.8534
vif(car.Model11)

#Removing carCompanycadillac p-value: 0.0751
car.Model12<-lm(formula = MPG ~ Weight + Acceleration + Cylinders4 + Cylinders5 + 
                  Cylinders6 + Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                  carModelBinBetween2009.2012 + carCompanydatsun + 
                  carCompanypontiac, 
                data = carmileage.train)

summary(car.Model12) #R-squared :0.8522
vif(car.Model12)

#Removing Cylinders6 p-value: 0.2711
car.Model13<- lm(formula = MPG ~ Weight + Acceleration + Cylinders4 + Cylinders5 + 
                   Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                   carModelBinBetween2009.2012 + carCompanydatsun + 
                   carCompanypontiac, 
                 data = carmileage.train)

summary(car.Model13) #R-squared :0.8521
vif(car.Model13)

#Removing carCompanypontiac p-value: 0.05491
car.Model14<-lm(formula = MPG ~ Weight + Acceleration + Cylinders4 + Cylinders5 + 
                  Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                  carModelBinBetween2009.2012 + carCompanydatsun,
                data = carmileage.train)

summary(car.Model14) #R-squared :0.8506
vif(car.Model14)

#Removing carCompanydatsun p-value: 0.0262 
car.Model15<-lm(formula = MPG ~ Weight + Acceleration + Cylinders4 + Cylinders5 + 
                  Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                  carModelBinBetween2009.2012,
                data = carmileage.train)

summary(car.Model15) #R-squared :0.8483
vif(car.Model15)

#Removing Cylinders5 p-value 0.0195
 
car.Model16<-lm(formula = MPG ~ Weight + Acceleration + Cylinders4 + 
                  Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                  carModelBinBetween2009.2012,
                data = carmileage.train)

summary(car.Model16) #R-squared :0.8458
vif(car.Model16)
 
#Removing Acceleration p-value 0.009471

car.Model17<-lm(formula = MPG ~ Weight + Cylinders4 + 
                  Cylinders8 + carModelBin2013orLater + carModelBinBetween2006.2008 + 
                  carModelBinBetween2009.2012,
                data = carmileage.train)
summary(car.Model17) #R-squared :0.8425
vif(car.Model17)

#Removing Cylinders8 p-value 0.00152
car.Model18<-lm(formula = MPG ~ Weight + Cylinders4 + 
                  carModelBin2013orLater + carModelBinBetween2006.2008 + 
                  carModelBinBetween2009.2012,
                data = carmileage.train)
summary(car.Model18) #R-squared :0.8371
vif(car.Model18)

#Removing Cylinders4 p-value 1.18e-05 VIF 2.912682
car.Model19<-lm(formula = MPG ~ Weight + 
                  carModelBin2013orLater + carModelBinBetween2006.2008 + 
                  carModelBinBetween2009.2012,
                data = carmileage.train)
summary(car.Model19) #R-squared :0.8258
vif(car.Model19)

########Checkpoint 4############
# Model evaluation and testing
#-----------------------------

#Analysis of test data
#Using test data and running final regression formula on it
car.Model.test<-lm(formula = MPG ~ Weight + 
                  carModelBin2013orLater + carModelBinBetween2006.2008 + 
                  carModelBinBetween2009.2012,
                data = carmileage.test)
summary(car.Model.test) #R-squared :0.811
vif(car.Model.test)

# Final regression equation to predict MPG :
# EstimatedMpg = 48.0014310 + (-0.0065884*Weight) + (-7.5540290*carModelBin2013orLater) 
# + (-4.2541915*carModelBinBetween2006.2008)
# + (-7.1354110*carModelBinBetween2009.2012)

# Verifying the estimate with test dataset using regression formula
carmileage.test$EstimatedMPG<-48.0014310 + (-0.0065884*carmileage.test$Weight) + 
  (-7.5540290*carmileage.test$carModelBin2013orLater) + 
  (-4.2541915*carmileage.test$carModelBinBetween2006.2008) + 
  (-7.1354110*carmileage.test$carModelBinBetween2009.2012)

# Calculating ErrorSquare and SumofSquares
carmileage.test$ErrorSquare<-(carmileage.test$MPG-carmileage.test$EstimatedMPG)^2
carmileage.test$SumofSquares<-(carmileage.test$MPG-mean(carmileage.test$MPG))^2

# Calculating r-Square
rSquare.test<-1-(sum(carmileage.test$ErrorSquare)/sum(carmileage.test$SumofSquares))

rSquare.test

# Plot 1
# ------
# Plotting MPG and EstimatedMPG for each car company

# Applying regression formula on the entire data set
carmileage.final$EstimatedMPG<-48.0014310 + (-0.0065884*carmileage.final$Weight) + 
  (-7.5540290*carmileage.final$carModelBin2013orLater) + 
  (-4.2541915*carmileage.final$carModelBinBetween2006.2008) + 
  (-7.1354110*carmileage.final$carModelBinBetween2009.2012)

# Adding Car Company to final dataset
carmileage.final$carCompany<-carmileage$carCompany

# Adding error variable (MPG-EstimatedMPG)
carmileage.final$error<-carmileage.final$MPG-carmileage.final$EstimatedMPG

# Creating a data frame with average MPG and Average EstimatedMPG for each car company
carmileage.plot<-merge(x=aggregate(MPG ~ carCompany,data=carmileage.final,mean),
                       y=aggregate(EstimatedMPG ~ carCompany,data=carmileage.final,mean),by = "carCompany",all=TRUE)


dat_1 <- melt(carmileage.plot, id.vars = "carCompany")
plot1 <- ggplot(data = dat_1, aes(x = carCompany, y = value, group = variable, fill = variable))
plot1 <- plot1 + scale_x_discrete(labels = abbreviate)
plot1 <- plot1 + geom_bar(stat = "identity", width = 0.5, position = "dodge")
plot1 <- plot1 + ggtitle("Average MPG and Average EstimatedMPG for Each Car Company")
plot1

# Plotting Error Vs. MPG
plot2<-ggplot(carmileage.final,aes(x=MPG,y=error,color=carCompany))+geom_point()
plot2<-plot2+ggtitle("Error Vs. MPG")
plot2

# Plots created from the model
plot(car.Model.test)

########Checkpoint 5############

# Number of variables = 4
# r-Square of test data =  0.8114772
# VIF values :
# 1. Weight : 1.148580
# 2. carModelBin2013orLater : 1.621131
# 3. carModelBinBetween2006.2008 : 1.659832
# 4. carModelBinBetween2009.2012 : 1.812924

# Regression formula :
# EstimatedMpg = 48.0014310 + (-0.0065884*Weight) + (-7.5540290*carModelBin2013orLater) 
# + (-4.2541915*carModelBinBetween2006.2008)
# + (-7.1354110*carModelBinBetween2009.2012)

# Business contraints :
# The model should not contain more than 5 variables. FULFILLED
# According to the business needs, set the VIF to 2. FULFILLED
# The model should be highly predictive in nature i.e it should show 80% (R squared) of accuracy. FULFILLED

# We accept the regression formula as it accurately estimates MPG upto 81%

#Correlation between MPG and Estimated MPG in the test dataset
cor(carmileage.test$MPG,carmileage.test$EstimatedMPG) #Corelation=0.9
                                                        
