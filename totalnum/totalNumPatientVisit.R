# Author: Nicolas PARIS nicolas.paris@riseup.net
# Needs: data.table V1.9.4 & later
# may difers from fields of visit/patient dimension
args <- commandArgs(trailingOnly = TRUE)
library(data.table)
# PATIENT
# 1 :   SELECT patient_num, vital_status_cd, age_in_years_num, sex_cd, zip_cd FROM patient_dimension
# 2 : ont SELECT c_fullname, c_columnname, c_operator, c_dimcode , c_columndatatype FROM i2b2 WHERE c_tablename LIKE 'patient_dimension' AND c_visualattributes NOT LIKE 'C%' AND c_metadataxml IS NULL
# 3 : file out 
# VISIT
# 1 :  visit SELECT patient_num, inout_cd, length_of_stay, age_visit_in_years_num FROM visit_dimension
# 2 : ont SELECT c_fullname, c_columnname, c_operator, c_dimcode , c_columndatatype FROM i2b2 WHERE c_tablename LIKE 'visit_dimension' AND c_visualattributes NOT LIKE 'C%' AND c_metadataxml IS NULL
# 3 : file out 

#new operator : remove from vector
"%-%"<-function(a,b){
a[!a%in%b]
}

#convert SQL syntax in R syntax
transformSql2R<-function(champs,c_operator,c_columnname,c_dimcode,c_columndatatype){
	c_operator<-tolower(c_operator)
dcast<-ifelse(c_columndatatype%in%"N","as.numeric(","")
fcast<-ifelse(c_columndatatype%in%"N",")","")

rq<-ifelse(c_columndatatype%in%"T","'","")
ret<-ifelse(grepl("[><=]+",c_operator),
	    paste0("patient_num[",dcast,c_columnname,fcast,gsub("^=$","==",c_operator),rq,c_dimcode,rq,"]")
       ,ifelse(c_operator%in%"between",
	       paste0("patient_num[between(",dcast,c_columnname,fcast,",",gsub("[A-z]+",",",c_dimcode),")]")
	       ,ifelse(grepl("is",c_operator),
		       paste0("patient_num[",ifelse(grepl("not",c_operator),"!",""),"is.na(",dcast,c_columnname,fcast,")]")
		       ,ifelse(grepl("like",c_operator),
 		     paste0("patient_num[grepl('^",gsub("['%]","",c_dimcode),".*$',",c_columnname,")]")
			       ,"1"))))

paste0("\"",champs,"\"=length(unique(unlist(strsplit(paste0(",ret,",collapse=','),','))))")
}


pat<-fread(file.path(args[1]),colClasses="character",header=T,sep=";")
ont<-fread(file.path(args[2]),colClasses="character",header=T,sep=";")
if(nrow(pat)!=0){
ab<-ont
ab[,calc:=paste(c_columnname,c_operator,c_dimcode)]
su<-pat[,eval(parse(text=paste0("list(",paste0(transformSql2R(ab$calc,ab$c_operator,ab$c_columnname,ab$c_dimcode,ab$c_columndatatype),collapse=","), ")"))),]
a<-data.frame(row.names(t(su)),t(su)[,1],stringsAsFactors=F)
setnames(a,c("calc","c_totalnum"))
add<-merge(as.data.frame(ab), a ,by="calc")
add<-add[,c("c_fullname","c_totalnum")]
add<-add[!duplicated(add$c_fullname),]
res<-add
}else{
res<-data.table("c_fullname"=ont$c_fullname,"c_totalnum"="0")
}
write.table(res,file.path(args[3]), fileEncoding="utf8",row.names=F,sep=";",quote=T)
