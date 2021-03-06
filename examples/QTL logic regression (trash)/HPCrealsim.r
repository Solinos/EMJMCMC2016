# ssh -X -Y -l aliaksah abel.uio.no
# scp -r  /usit/abel/u1/aliaksah/simulations/ aliaksah@pittheus.uio.no://mn/sarpanitu/ansatte-u2/aliaksah/Desktop/package/simulations
# cat slurm-16078690.out
# squeue -u aliaksah
# qlogin --account=nn9244k --nodes=1 --exclusive --time 5:00:00

source("https://raw.githubusercontent.com/aliaksah/EMJMCMC2016/master/R/the_mode_jumping_package2.r")


X<-read.csv("https://raw.githubusercontent.com/aliaksah/EMJMCMC2016/master/examples/QTL%20logic%20regression/qtlX")[,-1]


formula1 = as.formula(paste(colnames(X)[221],"~ 1 +","I((((((((((NGA1107)&((MSAT4.39)))|((NGA1145)))&((ZFPG))))))))) + I((X21607021)|((X21607259))) + I((((((((((NGA1107)&((MSAT4.39)))|((NGA1145)))&((ATHATPASE))))))))&((ZFPG))) +I(((MSAT4.39)|((((X21607021)|((X44607038)))&((X44606875))))))+I(NGA1107)+I(NGA8)+I(X44607038)+I((NGA8)&((X44607038)))"))

X <- as.data.frame(X)

X<-data.example
#
# coef<-estimate.logic.lm(formula = formula1,data = data.example,n = 2000 ,m = 200)$summary.fixed$mean
#
# print(coef)


library(inline)
includes <- '#include <sys/wait.h>'
code <- 'int wstat; while (waitpid(-1, &wstat, WNOHANG) > 0) {};'
wait <- cfunction(body=code, includes=includes, convention='.C')


parall.gmj <<- mclapply



simplifyposteriors<-function(X,posteriors,th=0.0001,thf=0.5)
{
  posteriors<-posteriors[-which(posteriors[,2]<th),]
  rhash<-hash()
  for(i in 1:length(posteriors[,1]))
  {
    expr<-posteriors[i,1]
    print(expr)
    res<-model.matrix(data=X,object = as.formula(paste0("V1~",expr)))
    res[,1]<-res[,1]-res[,2]
    ress<-c(stri_flatten(res[,1],collapse = ""),stri_flatten(res[,2],collapse = ""),posteriors[i,2],expr)
    if(!(ress[1] %in% values(rhash)||(ress[2] %in% values(rhash))))
      rhash[[ress[1]]]<-ress
    else
    {
      if(ress[1] %in% keys(rhash))
      {
        rhash[[ress[1]]][3]<- (as.numeric(rhash[[ress[1]]][3]) + as.numeric(ress[3]))
        if(stri_length(rhash[[ress[1]]][4])>stri_length(expr))
          rhash[[ress[1]]][4]<-expr
      }
      else
      {
        rhash[[ress[2]]][3]<- (as.numeric(rhash[[ress[2]]][3]) + as.numeric(ress[3]))
        if(stri_length(rhash[[ress[2]]][4])>stri_length(expr))
          rhash[[ress[2]]][4]<-expr
      }
    }

  }
  res<-as.data.frame(t(values(rhash)[c(3,4),]))
  res$V1<-as.numeric(as.character(res$V1))
  res<-res[which(res$V1>thf),]
  res<-res[order(res$V1, decreasing = T),]
  clear(rhash)
  rm(rhash)
  res[which(res[,1]>1),1]<-1
  colnames(res)<-c("posterior","tree")
  return(res)
}


MM = 100
M = 32
NM= 1000
compmax = 26
th<-(10)^(-5)
thf<-0.05

paral<-function(X,FUN)
{
  return(mclapply(X = X,FUN = FUN,mc.preschedule = F, mc.cores = 32))
}


runpar<-function(vect)
{

  set.seed(as.integer(vect[22]))
  do.call(runemjmcmc, vect[1:21])
  vals<-values(hashStat)
  fparam<-mySearch$fparam
  cterm<-max(vals[1,],na.rm = T)
  ppp<-mySearch$post_proceed_results_hash(hashStat = hashStat)
  post.populi<-sum(exp(values(hashStat)[1,][1:NM]-cterm),na.rm = T)
  clear(hashStat)
  rm(hashStat)
  rm(vals)
  return(list(post.populi = post.populi, p.post =  ppp$p.post, cterm = cterm, fparam = fparam))
}



for(j in 1:MM)
{

  set.seed(j)


  Y<-rnorm(n = 210,mean = 42449-46*((((((((((X$NGA1107)&((X$MSAT4.39)))|((X$NGA1145)))&((X$ZFPG)))))))))+35*(((X$X21607021) | ((X$X21607259)))) + 80*((((((((((X$NGA1107) & ((X$MSAT4.39))) | ((X$NGA1145))) & ((X$ATHATPASE)))))))) & ((X$ZFPG)))+ 34*((X$NGA8) & ((X$X44607038)))
            -20*X$NGA1107-13*X$NGA8 + 31*X$X44607038,sd = 75)
  X$Y<-Y

  idss<-which(abs(cor(x = X,y=X$Y))>0.05)

  formula1 = as.formula(paste(colnames(X)[221],"~ 1 +",paste0(colnames(X)[idss][-length(idss)],collapse = "+")))
  data.example = as.data.frame(X)


  vect<-list(formula = formula1,data = X,outgraphs=F,estimator = estimate.logic.lm,presearch = T, locstop = F,estimator.args =  list(data = data.example,n = 2000, m = length(idss)),recalc_margin = 249, save.beta = F,interact = T,relations = c("","lgx2","cos","sigmoid","tanh","atan","erf"),relations.prob =c(0.4,0.0,0.0,0.0,0.0,0.0,0.0),interact.param=list(allow_offsprings=1,mutation_rate = 250,last.mutation = 5000, max.tree.size = 4, Nvars.max =25,p.allow.replace=0.9,p.allow.tree=0.2,p.nor=0,p.and = 0.9),n.models = 10000,unique = T,max.cpu = 4,max.cpu.glob = 4,create.table = F,create.hash = T,pseudo.paral = T,burn.in = 50,print.freq = 1000,advanced.param = list(
    max.N.glob=as.integer(10),
    min.N.glob=as.integer(5),
    max.N=as.integer(3),
    min.N=as.integer(1),
    printable = F))

  params <- list(vect)[rep(1,32)]

  for(i in 1:M)
  {
    params[[i]]$cpu<-i
    params[[i]]$simul<-"scenario_3_"
    params[[i]]$simid<-j
  }
  gc()
  print(paste0("begin simulation ",j))
  results<-parall.gmj(X = params,FUN = runpar,mc.preschedule = T, mc.cores = M)
  #print(results)
  wait()
  resa<-array(data = 0,dim = c(compmax,M*3))
  post.popul <- array(0,M)
  max.popul <- array(0,M)
  for(k in 1:M)
  {
    max.popul[k]<-results[[k]]$cterm
    post.popul[k]<-results[[k]]$post.populi
    resa[,k*3-2]<-c(results[[k]]$fparam,"Post.Gen.Max")
    resa[,k*3-1]<-c(results[[k]]$p.post,results[[k]]$cterm)
    resa[,k*3]<-rep(post.popul[k],length(results[[k]]$p.post)+1)
  }
  gc()
  rm(results)
  ml.max<-max(max.popul)
  post.popul<-post.popul*exp(-ml.max+max.popul)
  p.gen.post<-post.popul/sum(post.popul)
  hfinal<-hash()
  for(ii in 1:M)
  {
    resa[,ii*3]<-p.gen.post[ii]*as.numeric(resa[,ii*3-1])
    resa[length(resa[,ii*3]),ii*3]<-p.gen.post[ii]
    if(p.gen.post[ii]>0)
    {
      for(jj in 1:(length(resa[,ii*3])-1))
      {
        if(resa[jj,ii*3]>0)
        {
          #print(paste0(ii,"  and ",jj))
          if(as.integer(has.key(hash = hfinal,key =resa[jj,ii*3-2]))==0)
            hfinal[[resa[jj,ii*3-2]]]<-as.numeric(resa[jj,ii*3])
          else
            hfinal[[resa[jj,ii*3-2]]]<-hfinal[[resa[jj,ii*3-2]]]+as.numeric(resa[jj,ii*3])
        }

      }
    }
  }

  posteriors<-values(hfinal)
  clear(hfinal)
  rm(hfinal)
  rm(resa)
  rm(post.popul)
  rm(max.popul)
  posteriors<-as.data.frame(posteriors)
  posteriors<-data.frame(X=row.names(posteriors),x=posteriors$posteriors)
  posteriors$X<-as.character(posteriors$X)
  tryCatch({
    res1<-simplifyposteriors(X = X,posteriors = posteriors, th,thf)
    write.csv(x =res1,row.names = F,file = paste0("post3eta_",j,".csv"))
  },error = function(err){
    print("error")
    write.csv(x =posteriors,row.names = F,file = paste0("posteriors3eta_",j,".csv"))
  },finally = {

    print(paste0("end simulation ",j))

  })
  rm(X)
  rm(data.example)
  rm(vect)
  rm(params)
  gc()
  print(paste0("end simulation ",j))

}
