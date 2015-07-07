# Castle Of Cards Algorithm
# Author: Nicolas PARIS nicolas.patis@riseup.net
# Needs: data.table V1.9.4 & later
library(data.table)
# ARGS for FACTS:
# 1 : select distinct patient_num, concept_cd from observation_fact WHERE modifier_cd = '@'
# 2 : select concept_path, concept_cd from concept_dimension
# 3 : select c_fullname from i2b2 WHERE c_tablename LIKE 'concept_dimension'
# 4 : file out name
# ARGS for PROVIDER:
# 1 : SELECT DISTINCT patient_num, provider_id as concept_cd FROM observation_fact  WHERE modifier_cd = '@'
# 2 : SELECT provider_path as concept_path, provider_id as concept_cd FROM provider_dimension
# 3 : select c_fullname from i2b2 WHERE c_tablename LIKE 'provider_dimension'
# 4 : file out name
args <- commandArgs(trailingOnly = TRUE)
obsfact <- args[1]
cptdim  <- args[2]
onto    <- args[3]
out     <- args[4]

obsfact <- fread(file.path(obsfact), colClasses=c("integer","character"), header=T, sep=";")
cptdim  <- fread(file.path(cptdim), colClasses="character", header=T, sep=";")
onto    <- fread(file.path(onto), colClasses="character", header=T, sep="\n")

if(nrow(obsfact)!=0){
setkey(obsfact, concept_cd)
setkey(cptdim, concept_cd)
obsfact <- merge(obsfact,cptdim,by="concept_cd",allow.cartesian=T)
rm(cptdim)
chut<-gc()
obsfact[,concept_cd:=NULL]
setkey(obsfact,concept_path)
obsfact <- obsfact[,.(list(patient_num)),by=concept_path]
setnames(obsfact,"V1","patient_num")
obsfact <- obsfact[!duplicated(concept_path),]
obsfact[,nb:=nchar(gsub("[^\\]+","",concept_path))-1]
res <- data.table("concept_path"=rep(obsfact$concept_path,obsfact$nb), "patient_num"=rep(obsfact$patient_num,obsfact$nb))
rm(obsfact)
chut <- gc()
res[,taille:=0:(.N-1),by=concept_path]
res <- res[order(concept_path,taille)]
res[,concept_path:=mapply(function(x,y){gsub(x,"",y)},paste0(lapply(res$taille,function(x){paste0(rep("[^\\]+[\\]",x),collapse="")}),"$"),concept_path)]
res <- res[!concept_path%chin%"\\i2b2\\",]
res[,c("taille"):=NULL]
res <- res[, .(list(unlist(patient_num))), by=concept_path]
setnames(res,"V1","patient_num")
res[,patient_num:=sapply(patient_num, function(x)length(unique(x)))]
setnames(res, c("c_fullname","c_totalnum"))
res <- rbind(res, data.table("c_fullname"=onto$c_fullname[!onto$c_fullname%chin%res$c_fullname], "c_totalnum"="0"))
}else{
res <- data.table("c_fullname"=onto$c_fullname,"c_totalnum"="0")
}
write.table(res, file.path(out), row.names=F, fileEncoding="utf8", sep=";", quote=T)
