##########################################################################
#R Program to calculate input oriented TE Model
#Model is taken from "Production Frontiers" (1994) by Fare, Grosskopf and Lovell
#This version calculates a VRS model
####################################################################
#First Clear any previous data stored in memory, and require Rglpk
rm(list=ls())
library(Rglpk)
library(Benchmarking)
library(dplyr)
library(ompr)
######################################################
#Beginning of Data Step
####################################################################
data(charnes1981)
df1<-charnes1981
#df1<-df1[1:10,]
###################################################################
J=nrow(df1)                            #Number of observations
# Create input X matrix
X<-as.matrix(df1[,c("x1","x2","x3","x4","x5")]) 
# Create output Y matrix
Y<-as.matrix(df1[,c("y1","y2","y3")])  
m<-colnames(Y)                         #Read column names of Y into m
M=length(m)
n<-colnames(X)                         #Read column names of X into m
N=length(n)
jp=1                                   #set j=1 for initial DEA matrix
################################################################################
###############################################################################
#Set-up the DEA model using OMPR for one observation. This step sets up the A 
#matrix, rhs values and objective function to use in DEA Model
###############################################################################
model1<-MIPModel() %>%
  add_variable(z[j],j=1:J, lb=0) %>%
  add_variable(theta, lb=0, ub=Inf) %>%
  set_objective(1*theta,"min") %>%
  add_constraint(sum_over(z[j]*Y[j,m], j = 1:J) >= Y[jp,m], m = 1:M) %>%
  add_constraint(sum_over(z[j]*X[j,n], j = 1:J) <= theta*X[jp,n], n = 1:N)%>%
  add_constraint(sum_over(z[j], j=1:J) ==1)
###############################################################################
#End of using OMPR to define initial problem
#Next, extract parts of Model 1 needed to build A matrix
################################################################################
vnames1 = variable_keys(model1)                      #Extract the name of the 
#variables for this model 
obj1=as.vector(objective_function(model1)$solution); #Extract objective function values
names(obj1)=vnames1;                                 #set names for the objective function 
constraints1 <- (extract_constraints(model1))        #set constraints
################################################################################
#Set up A matrix and run for multiple observations
################################################################################
A = as.matrix(constraints1$matrix); 
colnames(A)=vnames1; 
dirs1 = constraints1$sense       #Signs for Constraints
S=ncol(A)                        #Determine number of columns in A matrix
                                 #last column in A is changed for each loop
                                 #of the DEA model
################################################################################
#Start of loop to solve DEA models
################################################################################
res=0
status=0
for(s in 1:(S-1)){
  
  A[(M+1):(M+N),S]=-A[(M+1):(M+N),s]         #replace last column in A for n inputs 
                                             #by negative s A column for input 
                                             #oriented model
  
  rhs=c(A[(1:M),s],rep(0,N),1)               #rhs is zero for outputs
  sol<- Rglpk_solve_LP(obj=obj1, mat=A, dir=dirs1, rhs=rhs,max=F) 
  #Solve using RGLPK
  status[(s)]=sol$status
  res[(s)]=round(sol$optimum,3)
  if(s%%100==0|s==S)  print(paste('on dmu',s,'of',S-1))
  
}
####################################################################################
e<-dea(X,Y,RTS="vrs",ORIENTATION="in")#Run dea model using Benchmarking package to test
bench<-round(e$objval,3)               #store results in data structure bench
###################################################################################
summary(status)              #See if everything Solved
summary(res)
summary(bench)
summary(res-bench)  #comparing results against those from the Benchmark program
###############################################################################
