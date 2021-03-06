


#Answer the below questions:
#a. Find out top 5 attributes having highest correlation (select only Numeric features).
#b. Find out top 3 reasons for having more crime in a city.
#c. Which all attributes have correlation with crime rate?


Crimes <- read.csv("D:\\ACADGILD\\Crimes_-_2001_to_present.csv", header=FALSE)
View(Crimes)

names(Crimes) <- c("Case", "Number", "Date", "Block", "IUCR", "Primary Type", "Description",
                   "Location Desc", "Arrest", "Domestic", "Beat", "District", "Ward", "Community Area",
                   "FBI Code", "X Coordinate", "Y Coordinate", "Year", "Updated On", 
                   "Latitude", "Longitude", "Location")
head(Crimes)
tail(Crimes)
str(Crimes)

Crimes <- na.omit(Crimes)
names(Crimes)
cmain <- cor(Crimes[c(11,12,13,14,18,20,21)])
cmain


#Covariance is nothing but a measure of correlation. On the contrary, correlation refers to the scaled form of covariance.
#The value of correlation lies between -1 and +1 and it is not influenced by the change in scale


#Correlation Coefficient
#The correlation coefficient of two variables in a data set equals to their covariance divided by the product of their individual standard deviations. 
#It is a normalized measurement of how the two are linearly related.
#If the correlation coefficient is close to 1, it would indicate that the variables are positively linearly related and the scatter plot falls almost along a straight line with positive slope. 
#If it is close to -1, it indicates that the variables are negatively linearly related and the scatter plot almost falls along a straight line with negative slope. 
#And for zero, it would indicate a weak linear relationship between the variables.


library(reshape2
library(dplyr)
m <- melt(cmain)
m
top <- m%>%select(X1, X2, value)%>%filter(value != 1)
top[order(top$value, decreasing = T)[1:10],]



x <- as.data.frame(table(Crimes$Description))
x[order(x$Freq, decreasing = T)[1:3],]

crime <- Crimes
head(crime)
table(is.na(crime))

crime$Date <- as.POSIXlt(crime$Date, format= "%m/%d/%Y %H:%M:%S")
crime$`Updated On` <- as.POSIXlt(crime$`Updated On`, format= "%m/%d/%Y %H:%M:%S")


library(chron)
crime$Time <- times(format(crime$Date,"%H:%M:%S"))
crime$Date <- as.POSIXct(crime$Date)
crime$`Updated On` <- as.POSIXct(crime$`Updated On`)


time.tag <- chron(times=c("00:00:00", "06:00:00", "12:00:00", "18:00:00","23:59:00"))
time.tag
crime$time.tag <- cut(crime$Time, breaks= time.tag,
                      labels= c("00-06","06-12", "12-18", "18-00"), include.lowest =TRUE)
table(crime$time.tag)


crime$date <- as.POSIXlt(strptime(crime$Date, format = "%Y-%m-%d"))
crime$date <- as.POSIXct(crime$date)


crime$day <- as.factor(weekdays(crime$Date, abbreviate = TRUE))
crime$month <- as.factor(months(crime$Date, abbreviate = TRUE))
str(crime$day)
str(crime$month)


crime$Arrest <- ifelse(as.character(crime$Arrest) == "true",1,0)


crime$crime <- as.character(crime$`Primary Type`)
crime$crime <- ifelse(crime$crime %in% c("CRIM SEXUAL ASSAULT","PROSTITUTION", "SEX OFFENSE","HUMAN TRAFFICKING"), 'SEX', crime$crime)
crime$crime <- ifelse(crime$crime %in% c("MOTOR VEHICLE THEFT"), "MVT", crime$crime)
crime$crime <- ifelse(crime$crime %in% c("GAMBLING", "INTERFEREWITH PUBLIC OFFICER", "INTERFERENCE WITH PUBLIC OFFICER", "INTIMIDATION",
                                         "LIQUOR LAW VIOLATION", "OBSCENITY", "NON-CRIMINAL", "PUBLIC PEACE VIOLATION",
                                         "PUBLIC INDECENCY", "STALKING", "NON-CRIMINAL (SUBJECT SPECIFIED)","NON - CRIMINAL"),
                      "NONVIO", crime$crime)
crime$crime <- ifelse(crime$crime == "CRIMINAL DAMAGE", "DAMAGE",crime$crime)
crime$crime <- ifelse(crime$crime == "CRIMINAL TRESPASS","TRESPASS", crime$crime)
crime$crime <- ifelse(crime$crime %in% c("NARCOTICS", "OTHER NARCOTIC VIOLATION", "OTHER NARCOTIC VIOLATION"), "DRUG", crime$crime)
crime$crime <- ifelse(crime$crime == "DECEPTIVE PRACTICE","FRAUD", crime$crime)
crime$crime <- ifelse(crime$crime %in% c("OTHER OFFENSE", "OTHEROFFENSE"), "OTHER", crime$crime)
crime$crime <- ifelse(crime$crime %in% c("KIDNAPPING", "WEAPONS VIOLATION", "CONCEALED CARRY LICENSE VIOLATION","OFFENSE INVOLVING CHILDREN"), "VIO", crime$crime)
table(crime$crime)



temp <- aggregate(crime$crime, by=list(crime$crime, crime$time.tag), FUN=length)
names(temp) <- c("crime", "time.tag", "count")
library(plyr)
temp <- ddply(crime, .(crime, day), summarise, count = length(date))

library(doBy)
temp <- summaryBy(Case ~ crime + month, data = crime, FUN= length)
names(temp)[3] <- 'count'

crime.agg <- ddply(crime, .(crime, Arrest, Beat, date, `X Coordinate`, `Y Coordinate`, time.tag, day, month),
                   summarise, count=length(date), .progress='text')

beats <- sort(unique(crime.agg$Beat))
dates <- sort(as.character(unique(crime.agg$date)))
temp <- expand.grid(beats, dates)
names(temp) <- c("Beat", "date")

model.data <- aggregate(crime.agg[, c('count', 'Arrest')], by=
                          list(crime.agg$Beat, as.character(crime.agg$date)), FUN=sum)
names(model.data) <- c("Beat", "date", "count", "Arrest")
model.data <- merge(temp, model.data, by= c('Beat', 'date'), all.x= TRUE)
View(model.data)
model.data$count[is.na(model.data$count)] <- 0
model.data$Arrest[is.na(model.data$Arrest)] <- 0
model.data$day <- weekdays(as.Date(model.data$date), abbreviate= TRUE)
model.data$month <- months(as.Date(model.data$date), abbreviate= TRUE)
pastDays <- function(x) {c(0, rep(1, x))}
model.data$past.crime.1 <- ave(model.data$count, model.data$Beat,
                               FUN=function(x) filter(x, pastDays(1), sides= 1))
model.data$past.crime.7 <- ave(model.data$count, model.data$Beat,
                               FUN=function(x) filter(x, pastDays(7), sides= 1))
model.data$past.crime.30 <- ave(model.data$count, model.data$Beat,
                                FUN=function(x) filter(x, pastDays(30), sides= 1))

meanNA <- function(x){mean(x, na.rm= TRUE)}
model.data$past.crime.1 <- ifelse(is.na(model.data$past.crime.1),
                                  meanNA(model.data$past.crime.1), model.data$past.crime.1)
model.data$past.crime.7 <- ifelse(is.na(model.data$past.crime.7),
                                  meanNA(model.data$past.crime.7), model.data$past.crime.7)
model.data$past.crime.30 <- ifelse(is.na(model.data$past.crime.30),
                                   meanNA(model.data$past.crime.30), model.data$past.crime.30)

model.data$past.arrest.30 <- ave(model.data$Arrest, model.data$Beat,
                                 FUN= function(x) filter(x, pastDays(30), sides= 1))
model.data$past.arrest.30 <- ifelse(is.na(model.data$past.arrest.30),
                                    meanNA(model.data$past.arrest.30), model.data$past.arrest.30)

model.data$policing <- ifelse(model.data$past.crime.30 == 0, 0,
                              model.data$past.arrest.30/model.data$past.crime.30)


model.data$crime.trend <- ifelse(model.data$past.crime.30 == 0, 0,
                                 model.data$past.crime.7/model.data$past.crime.30)


model.data$season <- as.factor(ifelse(model.data$month %in% c("Mar", "Apr", "May"), "spring",
                                      ifelse(model.data$month %in% c("Jun", "Jul", "Aug"), "summer",
                                             ifelse(model.data$month %in% c("Sep", "Oct","Nov"), "fall", "winter"))))

model.cor <- cor(model.data[, c("count", "past.crime.1", "past.crime.7",
                                "past.crime.30","policing", "crime.trend")])
model.cor
psych::cor.plot(model.cor)

mean(model.data$count)
var(model.data$count)


library(MASS)
model <- glm.nb(count ~past.crime.1 + past.crime.7 + past.crime.30 +
                  + policing + crime.trend + factor(day) + season, data= model.data)
summary(model)