##########################################################################
#R Program to calculate input oriented TE Model
#Model is taken from "Production Frontiers" (1994) by Fare, Grosskopf and Lovell
#This version calculates a CRS model using Charnes (1981) data
####################################################################
#First Clear any previous data stored in memory, and requires lpSolveAPI
rm(list=ls())
library(lpSolveAPI)
library(Benchmarking)
######################################################
#Beginning of Data Step
####################################################################
data(charnes1981)
df1<-charnes1981
###################################################################
# create input X matrix
X<-as.matrix(df1[,c("x1","x2","x3","x4","x5")])
# create output Y matrix
Y<-as.matrix(df1[,c("y1","y2","y3")])
###################################################################
(M=ncol(Y))
(N=ncol(X))
(J=nrow(X))
YX=cbind(Y,X)
###################################################################
#End of DATA Step
###################################################################
#Define A Matrix. M+N rows is for CRS. 
A=matrix(0,M+N,J+1)
#Next, Transform YX matrix and copy to A. 
A[1:(M+N),1:J]=t(YX)
#################################################################
objtype='min'
#set zero for all J colums, plus 1 for last colums
obj=c(rep(0,J),1)
rest=c(rep('>=',M),rep('<=',N))
#################################################################
nr=nrow(A) 
nc=ncol(A)
LP_API=make.lp(nrow=nr,ncol=nc)
lp.control(LP_API,sense='min')

set.objfn(LP_API,obj)
set.constr.type(LP_API,rest)

for(i in 1:nr){
  set.row(LP_API,i,A[i,])   #setting up rows by reading in A matrix rows
}
########################################################################
objval=0
status=0
for(j in 1:J){
  A[(M+1):(M+N),J+1]=-A[(M+1):(M+N),j]   #replace last column in A for n inputs 
                                         #by negative s A column for input 
                                         #oriented model
  
  rhs=c(as.matrix(Y[j,]),rep(0,N))       #rhs is being set to obs j output 
                                         #data, and zero for the input data
  set.rhs(LP_API,rhs) 
  set.column(LP_API,nc,A[,nc])           #loading revised A matrix into LPApi
  set.objfn(LP_API,obj)
  
  status[j]=solve(LP_API)
  objval[j]=round(get.objective(LP_API),3)
  
  if(j%%100==0|j==J)  print(paste('on dmu',j,'of',J))
  
} # end loop   for(j in 1:J)
###############################################################################
e<-dea(X,Y,RTS="crs",ORIENTATION="in")#Run dea model using Benchmarking package to test
bench<-round(e$objval,3)               #store results in data structure bench
###############################################################################
summary(status)
summary(objval)
summary(bench)
summary(objval-bench)
#############################################################################
