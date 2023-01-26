library(tidyverse)
library(AICcmodavg)
library(sjPlot)
library(lme4)
library(GLMsData)
library(statmod)
library(jtools)
library(rcompanion)
library(multcomp)
library(afex)
library(stargazer)
library(texreg)
library(xtable)
library(car)
library(MASS)
library(AICcmodavg)
library(tidyr)
library(ggplot2)
library(lme4)
library(interactions)

#read glm file
delim = ","
dec = "."
testResults = read.csv("C:/Users/aruni/OneDrive - Northern Illinois University/PhDProjects/CognitiveCorrelatesExperiment/Scripts/FinalScriptCogntiveCorrelatesExperiment/FinalScriptCogntiveCorrelatesExperiment/src/outputTables/outputForGLMM.csv", header=TRUE, sep=delim, dec=dec, stringsAsFactors=FALSE)

# Set predictors as categorical variables
testResults$Speed <- as.factor(testResults$Speed)
testResults$Number_of_Fish <- as.factor(testResults$Number_of_Fish)
testResults$CameraDistance <- as.factor(testResults$CameraDistance)

# Renaming predictors
testResults$Turbidity <- as.factor(testResults$Turbidity)
testResults$NumberFish <- as.factor(testResults$Number_of_Fish)
testResults$FishSpeed <- as.factor(testResults$Speed)

# Label the levels
levels(testResults$CameraDistance) <- c('Near', 'Far')
levels(testResults$Turbidity) <- c('Low', 'High')
levels(testResults$FishSpeed) <- c('Slow', 'Fast')

# GLM of different models
mod0 = glm(Net_Cognitive_Load~ 1 + (1|Subject)+ (1|Fish_Type), family = gaussian(link="identity"), data = testResults)
mod1 = glm(Net_Cognitive_Load~ 1  +  Turbidity +(1|Subject)+ (1|Fish_Type), family = gaussian(link="identity"), data = testResults)
mod2 = glm(Net_Cognitive_Load~ 1  + Turbidity + NumberFish + (1|Subject)  + (1|Fish_Type), family = gaussian(link="identity"), data = testResults)
mod3 = glm(Net_Cognitive_Load~ 1  + Turbidity + NumberFish + FishSpeed + (1|Subject)  + (1|Fish_Type), family = gaussian(link="identity"), data = testResults)
mod4 = glm(Net_Cognitive_Load~ 1  + Turbidity + NumberFish + FishSpeed + CameraDistance + (1|Subject)  + (1|Fish_Type), family = gaussian(link="identity"), data = testResults)
mod5 = glm(Net_Cognitive_Load~ 1  + FishSpeed + CameraDistance + Turbidity*NumberFish + (1|Subject)  + (1|Fish_Type), family = gaussian(link="identity"), data = testResults)
mod6 = glm(Net_Cognitive_Load~ 1  + NumberFish + CameraDistance + Turbidity*FishSpeed + (1|Subject)  + (1|Fish_Type), family = gaussian(link="identity"), data = testResults)
mod7 = glm(Net_Cognitive_Load~ 1  + Turbidity + CameraDistance + NumberFish*FishSpeed + (1|Subject)  + (1|Fish_Type), family = gaussian(link="identity"), data = testResults)
mod8 = glm(Net_Cognitive_Load~ 1  + NumberFish + FishSpeed + Turbidity*CameraDistance + (1|Subject)  + (1|Fish_Type), family = gaussian(link="identity"), data = testResults)
mod9 = glm(Net_Cognitive_Load~ 1  + Turbidity + FishSpeed + NumberFish*CameraDistance + (1|Subject)  + (1|Fish_Type), family = gaussian(link="identity"), data = testResults)
mod10 = glm(Net_Cognitive_Load~ 1  + Turbidity + NumberFish + FishSpeed*CameraDistance + (1|Subject)  + (1|Fish_Type), family = gaussian(link="identity"), data = testResults)

models <- list(mod0,mod1,mod2,mod3,mod4,mod5,mod6,mod7,mod8,mod9,mod10)

# Model comparison 
  #ANOVA
anova(mod0,mod1, test = "Chisq")
anova(mod1,mod2, test = "Chisq")
anova(mod2,mod3, test = "Chisq")
anova(mod3,mod4, test = "Chisq")
anova(mod4,mod5, test = "Chisq")

anova(mod4,mod6, test = "Chisq")
anova(mod4,mod7, test = "Chisq")
anova(mod4,mod8, test = "Chisq")
anova(mod4,mod9, test = "Chisq")
anova(mod4,mod10, test = "Chisq")

  #AICc
aictab(cand.set = models, modnames = c('mod0','mod1','mod2','mod3','mod4','mod5','mod6','mod7','mod8','mod9','mod10'))


#
jpeg(file="C:\Users\aruni\OneDrive - Northern Illinois University\PhDProjects\CognitiveCorrelatesExperiment\Scripts\FinalScriptCogntiveCorrelatesExperiment\FinalScriptCogntiveCorrelatesExperiment\src\Figure6_av.jpg", width = 36, height = 30, units = "cm", res = 400)
plot1 = cat_plot(mod6, pred = Turbidity, modx = FishSpeed, mod2 = NumberFish, geom = "line",data = testResults,interval=FALSE)
plot1+ylab("Cognitive Load") + theme(text = element_text(size = 35))+ theme(axis.title = element_text(size = 30))+coord_fixed(ratio=5)+theme(axis.text.x = element_text(size = 38))+theme(axis.text.y = element_text(size = 38))+ theme(legend.text = element_text(size=36.5))+ theme(legend.title = element_text(size=36.5))+ theme( panel.grid.major = element_line(size = 1.5))
while (!is.null(dev.list()))  dev.off()

#
jpeg("Figure6_b.jpg", width = 25, height = 30, units = "cm", res = 400)
plot2 = cat_plot(mod6, pred = Turbidity, modx = FishSpeed, mod2 = CameraDistance, geom = "line",data = testResults,interval=FALSE)
plot2+ylab("Cognitive Load")+theme(text = element_text(size = 30)) + theme(legend.text = element_text(size=35))+ theme(legend.title = element_text(size=35),panel.grid.major = element_line(size = 1.5))
plot2 + theme(axis.title = element_text(size = 30))+coord_fixed(ratio=5.5)+theme(axis.text.x = element_text(size = 38))+theme(axis.text.y = element_text(size = 43),panel.grid.major = element_line(size = 1.5))
while (!is.null(dev.list()))  dev.off()

