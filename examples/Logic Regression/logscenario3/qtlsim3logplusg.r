# ssh -X -Y -l aliaksah abel.uio.no
# scp -r  /usit/abel/u1/aliaksah/simulations/scenario1  aliaksah@pittheus.uio.no://mn/sarpanitu/ansatte-u2/aliaksah/Desktop/package/simulations


source("https://raw.githubusercontent.com/aliaksah/EMJMCMC2016/master/R/the_mode_jumping_package2.r")

library(inline)
includes <- '#include <sys/wait.h>'
code <- 'int wstat; while (waitpid(-1, &wstat, WNOHANG) > 0) {};'
wait <- cfunction(body=code, includes=includes, convention='.C')



estimate.logic.glm <- function(formula = NULL, data, family, n, m, r = 1, p.a = 1, p.b = 2, p.r = 1.5, p.s = 0, p.v=-1, p.k = 1)
{
  out <- glm(formula = formula,family = family,data = data)
  p <- out$rank
  fmla.proc<-as.character(formula)[2:3]
  fobserved <- fmla.proc[1]
  fmla.proc[2]<-stri_replace_all(str = fmla.proc[2],fixed = " ",replacement = "")
  fmla.proc[2]<-stri_replace_all(str = fmla.proc[2],fixed = "\n",replacement = "")
  fparam <-stri_split_fixed(str = fmla.proc[2],pattern = "+",omit_empty = F)[[1]]
  sj<-(stri_count_fixed(str = fparam, pattern = "&"))
  sj<-sj+(stri_count_fixed(str = fparam, pattern = "|"))
  sj<-sj+1
  Jprior <- sum(log(factorial(sj)/((m^sj)*2^(2*sj-2))))
  mlik = (-(out$deviance + log(n)*(out$rank)) + 2*(Jprior))/2+n
  if(mlik==-Inf)
    mlik = -10000
  X <- scale(model.matrix(object = formula,data = data),center = T,scale = F)
  X[,1] = 1
  fmla.proc<-as.character(formula)[2:3]
  #out <- glm.fit(x =X,y = data[,y.id],family = binomial())
  #out <- glm(formula = formula,data=data,family = binomial())
  out <- glm(formula = as.formula(paste0(fmla.proc[1],"~X+0")),data=data,family = binomial())
  beta=coef(out)[-1]
  if(length(which(is.na(beta)))>0)
  {
    return(list(mlik = mlik, waic = -10000+ rnorm(1,0,1), dic =  10000,summary.fixed =list(mean = 0)))
  }
  p <- out$rank
  fmla.proc[2]<-stri_replace_all(str = fmla.proc[2],fixed = " ",replacement = "")
  fmla.proc[2]<-stri_replace_all(str = fmla.proc[2],fixed = "\n",replacement = "")
  fparam <-stri_split_fixed(str = fmla.proc[2],pattern = "+",omit_empty = F)[[1]]
  sj<-(stri_count_fixed(str = fparam, pattern = "&"))
  sj<-sj+(stri_count_fixed(str = fparam, pattern = "|"))
  sj<-sj+1
  p.v = (n+1)/(p+1)
  sout = summary(out)
  J.a.hat = 1/sout$cov.unscaled[1,1]
  if(length(beta)>0&&length(beta)==(dim(sout$cov.unscaled)[1]-1)&&length(which(is.na(beta)))==0)
  {
    Q = t(beta)%*%solve(sout$cov.unscaled[-1,-1])%*%beta
  }else{
    return(list(mlik = mlik, waic = -10000+ rnorm(1,0,1), dic =  10000,summary.fixed =list(mean = 0)))
  }
  
  Jprior <- sum(log(factorial(sj)/((m^sj)*2^(2*sj-2))))
  waic = (logLik(out)- 0.5*log(J.a.hat) - 0.5*p*log(p.v) -0.5*Q/p.v + log(beta((p.a+p)/2,p.b/2)) + log(phi1(p.b/2,p.r,(p.a+p.b+p)/2,(p.s+Q)/2/p.v,1-p.k))+Jprior + p*log(r)+n)
  if(is.na(mlik)||mlik==-Inf)#||mlik==Inf)
    waic = -10000+ rnorm(1,0,1)
  return(list(mlik = mlik,waic = waic , dic =  -(out$deviance + log(n)*out$rank),summary.fixed =list(mean = coefficients(out))))
}



parall.gmj <<- mclapply


simplifyposteriors<-function(X,posteriors,th=0.0001,thf=0.5)
{
  posteriors<-posteriors[-which(posteriors[,2]<th),]
  rhash<-hash()
  for(i in 1:length(posteriors[,1]))
  {
    expr<-posteriors[i,1]
    print(expr)
    res<-model.matrix(data=X,object = as.formula(paste0("Y1~",expr)))
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
compmax = 16
th<-(10)^(-5)
thf<-0.05

paral<-function(X,FUN)
{
  return(mclapply(X = X,FUN = FUN,mc.preschedule = T, mc.cores = 32))
}

runpar<-function(vect)
{

  tryCatch({
    set.seed(as.integer(vect[24]))
    do.call(runemjmcmc, vect[1:23])
    vals<-values(hashStat)
    fparam<-mySearch$fparam
    cterm<-max(vals[1,],na.rm = T)
    ppp<-mySearch$post_proceed_results_hash(hashStat = hashStat)
    post.populi<-sum(exp(values(hashStat)[1,][1:NM]-cterm),na.rm = T)

    mliks <- values(hashStat)[which((1:(lHash * 3)) %%3 == 2)]
    xyz<-which(mliks!=-10000)
    moddee<-which( mliks ==max(mliks ,na.rm = TRUE))[1]
    zyx<-array(data = NA,dim = lHash)
    nconsum<-sum(exp(- mliks[moddee]+ mliks[xyz]),na.rm = TRUE)
    
    if( nconsum > 0)
    {
      zyx[xyz]<-exp(mliks[xyz]- mliks[moddee])/nconsum
      
    }else{
      
      diff<-0-mliks[moddee]
      mliks<-mliks+diff
      nconsum<-sum(exp(- mliks[moddee]+ mliks[xyz]),na.rm = TRUE)
      zyx[xyz]<-exp(mliks[xyz]- mliks[moddee])/nconsum
      
    }
    
    
    keysarr <- as.array(keys(hashStat))
    p.post<-array(data = 0,dim = Nvars)
    for(i in 1:lHash)
    {
      if(is.na(zyx[i]))
        next
      #vec<-dectobit(strtoi(keysarr[i], base = 0L)-1) # we will have to write some function that would handle laaaaargeee integers!
      varcur<- as.integer(strsplit(keysarr[i],split = "")[[1]])
      p.post <- (p.post + varcur*zyx[i])
      
    }
    
    if(sum(p.post)==0 || sum(p.post)>Nvars)
    {
      p.post <- array(data = 0.5,dim = Nvars)
    }
    
    p.post.g = p.post 
    m.post.g = zyx
    s.mass.g = sum(exp(mliks))
    cterm.g  = max(vals[2,],na.rm = T)
    post.populi.g<-sum(exp(values(hashStat)[2,][1:NM]-cterm.g),na.rm = T)
    
    
    ret <- list(post.populi = post.populi, p.post =  ppp$p.post,m.mpost =  ppp$m.post, cterm = cterm,post.populi.g = post.populi.g, p.post.g =  p.post.g, cterm.g = cterm.g,m.post.g = m.post.g, fparam = fparam)
     if(length(cterm)==0){
     print(ppp$p.post)
     print(fparam)
     print(cterm)
     print(vals[1,1:50])
      print(paste0("warning in thread",vect[24]))
      vect[24]<-as.integer(vect[24])+as.integer(runif(1,1,10000))
	ret <- runpar(vect)
    }
  },error = function(err){
   print(paste0("error in thread",vect[24]))
    vect[24]<-as.integer(vect[24])+as.integer(runif(1,1,10000))
    ret <- runpar(vect)
  },finally = {
    
    clear(hashStat)
    rm(hashStat)
    rm(vals)
    gc()
   # print(ret)
    return(ret)

  })
}

#print("wait 2 hours")
#Sys.sleep(7200)

for(j in 1:10)
{

  resa<-array(data = 0,dim = c(compmax,M*3))
  post.popul <- array(0,M)
  max.popul <- array(0,M)
  set.seed(j)
 
  X1<- as.data.frame(array(data = rbinom(n = 50*1000,size = 1,prob = runif(n = 50*1000,0,1)),dim = c(1000,50)))
  Y1<- 0.4 -9*(X1$V4*X1$V17*X1$V30*X1$V10) + 9*(X1$V7*X1$V20*X1$V12) - 5*(X1$V9*X1$V2)
  
  X1$Y1<-round(1.0/(1.0+exp(-Y1)))

  formula1 = as.formula(paste(colnames(X1)[51],"~ 1 +",paste0(colnames(X1)[-c(51)],collapse = "+")))
  data.example = as.data.frame(X1)

  vect<-list(formula = formula1,data = X1,presearch = T,locstop = F ,estimator = estimate.logic.glm,estimator.args =  list(data = data.example,family = binomial(),n = 1000, m = 50,r=1),recalc_margin = 250, save.beta = F,interact = T,relations = c("","lgx2","cos","sigmoid","tanh","atan","erf"),relations.prob =c(0.4,0.0,0.0,0.0,0.0,0.0,0.0),interact.param=list(allow_offsprings=1,mutation_rate = 300,last.mutation = 10000, max.tree.size = 4, Nvars.max = (compmax-1),p.allow.replace=0.9,p.allow.tree=0.2,p.nor=0.0,p.and = 0.9),n.models = 15000,unique = T,max.cpu = 4,max.cpu.glob = 4,create.table = F,create.hash = T,pseudo.paral = T,burn.in = 50,outgraphs=F,print.freq = 1000,advanced.param = list(
    max.N.glob=as.integer(10),
    min.N.glob=as.integer(5),
    max.N=as.integer(3),
    min.N=as.integer(1),
    printable = F))

  params <- list(vect)[rep(1,32)]

  for(i in 1:M)
  {
    params[[i]]$cpu<-i
    params[[i]]$simul<-"scenario_log_1_"
    params[[i]]$simid<-j
  }
  gc()
  print(paste0("begin simulation ",j))
  results<-parall.gmj(X = params,FUN = runpar,mc.preschedule = F, mc.cores = 32)
  gc()
  wait()

  print(results)
  
  resa<-array(data = 0,dim = c(compmax,M*3))
  post.popul <- array(0,M)
  max.popul <- array(0,M)
  nulls<-NULL
  not.null<-1
  for(k in 1:M)
  {
    if(length(results[[k]]$cterm)==0)
    {
	nulls<-c(nulls,k)
	next
    }
    else
    {
	not.null <- k
	write.csv(x = results[[k]]$m.post.g,file = paste0("/models/g.m.post",j,"_",k,".csv"))
	write.csv(x = results[[k]]$m.post,file = paste0("/models/j.m.post",j,"_",k,".csv"))
    }
   
  }
  

   for(k in 1:M)
  {
    if(k %in% nulls)
    {
	results[[k]]<-results[[not.null]]
    }
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
    res1<-simplifyposteriors(X = X1,posteriors = posteriors, th,thf)
    write.csv(x =res1,row.names = F,file = paste0("postLog3etaOld_",j,".csv"))},error = function(err){
      print("error")
      write.csv(x =posteriors,row.names = F,file = paste0("posteriorsLog3etaOld_",j,".csv"))},finally = {
        print(paste0("end simulation ",j))
      })
  
  
  
  resa<-array(data = 0,dim = c(compmax,M*3))
  post.popul <- array(0,M)
  max.popul <- array(0,M)
  nulls<-NULL
  not.null<-1
  for(k in 1:M)
  {
    if(length(results[[k]]$cterm.g)==0)
    {
      nulls<-c(nulls,k)
      next
    }
    else
    {
      not.null <- k
    }
    
  }
  
  
  for(k in 1:M)
  {
    if(k %in% nulls)
    {
      results[[k]]<-results[[not.null]]
    }
    max.popul[k]<-results[[k]]$cterm.g
    post.popul[k]<-results[[k]]$post.populi.g
    resa[,k*3-2]<-c(results[[k]]$fparam,"Post.Gen.Max")
    resa[,k*3-1]<-c(results[[k]]$p.post.g,results[[k]]$cterm.g)
    resa[,k*3]<-rep(post.popul[k],length(results[[k]]$p.post.g)+1)
    
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
    res1<-simplifyposteriors(X = X1,posteriors = posteriors, th,thf)
    write.csv(x =res1,row.names = F,file = paste0("postLog3g_",j,".csv"))},error = function(err){
      print("error")
      write.csv(x =posteriors,row.names = F,file = paste0("posteriorsLog3g_",j,".csv"))},finally = {
        print(paste0("end simulation ",j))
      })
  
  rm(X1)
  rm(data.example)
  rm(vect)
  rm(params)
  gc()
  print(paste0("end simulation ",j))

}


