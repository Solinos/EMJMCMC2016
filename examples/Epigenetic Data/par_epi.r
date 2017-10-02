# ssh -X -Y -l aliaksah abel.uio.no
# scp -r  /usit/abel/u1/aliaksah/simulations/scenario1  aliaksah@pittheus.uio.no://mn/sarpanitu/ansatte-u2/aliaksah/Desktop/package/simulations
# cat slurm-16078690.out
# squeue -u aliaksah
#
library("RCurl")
source("https://raw.githubusercontent.com/aliaksah/EMJMCMC2016/master/R/the_mode_jumping_package4.r")


cosi<-function(x)cos(x/180*pi)
sini<-function(x)sin(x/180*pi)
expi<-function(x)
{
  r<-exp(x)
  if(r==Inf)
    return(10000000)
  else
    return(r)
}

InvX<-function(x)
{
  if(x==0)
    return(10000000)
  else
    return(1/x)

}
troot<-function(x)abs(x)^(1/3)

MM = 100
M = 16
NM= 1000
compmax = 16
th<-(10)^(-5)
thf<-0.05



for(j in 1:1)
{
  tryCatch({

    set.seed(j)

    data.example <- read.table(text = getURL("https://raw.githubusercontent.com/aliaksah/EMJMCMC2016/master/examples/Epigenetic%20Data/epigen.txt"),sep = ",",header = T)[,2:30]
    data.example<-data.example[sample.int(dim(data.example)[1],200),]
    data.example$pos1 = data.example$pos
    data.example$pos2 = data.example$pos
    data.example$pos3 = data.example$pos


    fparams <-c(colnames(data.example )[c(8:10,12:17,21:24,29)],"f(data.example$pos,model=\"ar1\")","f(data.example$pos1,model=\"rw1\")","f(data.example$pos2,model=\"iid\")","f(data.example$pos3,model=\"ou\")")
    fobservs <- colnames(data.example)[5]

    formula1 = as.formula(paste(fobservs,"~ 1 +",paste0(fparams,collapse = "+")))
    # outgraphs=F

    vect<-list(formula = formula1,outgraphs=F,data = data.example,latnames = c("f(data.example$pos,model=\"ar1\")","f(data.example$pos1,model=\"rw1\")","f(data.example$pos2,model=\"iid\")","f(data.example$pos3,model=\"ou\")"),estimator = estimate.inla.poisson,estimator.args =  list(data = data.example),recalc_margin = 249, save.beta = F,interact = T,relations=c("cos","sigmoid","tanh","atan","sin","erf"),relations.prob =c(0.1,0.1,0.1,0.1,0.1,0.1),interact.param=list(allow_offsprings=3,mutation_rate = 250,last.mutation = 15000, max.tree.size = 4, Nvars.max =(compmax-1),p.allow.replace=0.7,p.allow.tree=0.2,p.nor=0,p.and = 0.9),n.models = 10000,unique = T,max.cpu = 4,max.cpu.glob = 4,create.table = F,create.hash = T,pseudo.paral = T,burn.in = 50,print.freq = 1000,advanced.param = list(
      max.N.glob=as.integer(10),
      min.N.glob=as.integer(5),
      max.N=as.integer(3),
      min.N=as.integer(1),
      printable = F))

    length(vect)
    
    params <- list(vect)[rep(1,M)]

    
    for(i in 1:M)
    {
  
      params[[i]]$cpu<-i*j
      params[[i]]$simul<-"scenario_epi_"
      params[[i]]$simid<-j
      params[[i]]$NM<-1000
      params[[i]]$simlen<-22
    }
    gc()
    
    gc()
    print(paste0("begin simulation ",j))
    results<-parall.gmj(X = params, M = M)

    print(results)
    
    resa<-array(data = 0,dim = c(compmax,M*3))
    post.popul <- array(0,M)
    max.popul <- array(0,M)
    nulls<-NULL
    
    not.null<-1
    for(k in 1:M)
    {
      if(is.character(results[[k]]))
      {
        nulls<-c(nulls,k)
        next
      }
      if(length(results[[k]])==0)
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
      max.popul[k]<-results[[k]]$cterm
      post.popul[k]<-results[[k]]$post.populi
      if(length(resa[,k*3-2])==(length(results[[k]]$fparam)+1))
      {
        resa[,k*3-2]<-c(results[[k]]$fparam,"Post.Gen.Max")
        resa[,k*3-1]<-c(results[[k]]$p.post,results[[k]]$cterm)
        resa[,k*3]<-rep(post.popul[k],length(results[[k]]$p.post)+1)
      }else
      {
        #idsx<-order(results[[k]]$p.post,decreasing = T,na.last = T)
        resa[,k*3-2]<-rep(results[[k]]$fparam[1],length(resa[,k*3-2]))
        resa[,k*3-1]<-rep(0,length(resa[,k*3-1]))
        resa[,k*3]<-rep(-10^9,length(resa[,k*3]))
        max.popul[k]<- -10^9
        post.popul[k]<- -10^9
      }
      
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
    
    #print(posteriors)
    clear(hfinal)
    rm(hfinal)
    rm(resa)
    rm(post.popul)
    rm(max.popul)
    posteriors<-as.data.frame(posteriors)
    posteriors<-data.frame(X=row.names(posteriors),x=posteriors$posteriors)
    posteriors$X<-as.character(posteriors$X)
    
    tryCatch({
      res1<-simplifyposteriors(X = data.example,posteriors = posteriors, th,thf,resp = "methylated_bases")
      row.names(res1)<-1:dim(res1)[1]
      write.csv(x =res1,row.names = F,file = paste0("postEPIGEN_",j,".csv"))
    },error = function(err){
      print("error")
      print(err)
      write.csv(x =posteriors,row.names = F,file = paste0("postEPIGENERR_",j,".csv"))
    },finally = {

      print(paste0("end simulation ",j))

    })
    rm(X)
    rm(data.example)
    rm(vect)
    rm(params)
    gc()
    print(paste0("end simulation ",j))
  },error = function(err){
    print("error")
    j=j-1
    print(paste0("repeat  simulation ",j))
  },finally = {

    print(paste0("end simulation ",j))
    rm(X4)
    rm(data.example)
    rm(vect)
    rm(params)
    gc()
  })

}
