image.bma <- function (x, top.models=20, intensity=TRUE, prob=TRUE, log=TRUE, rotate=TRUE, color="rainbow", subset=NULL, offset=.75, digits=3, vlas=2,plas=0,rlas=0, ...) 
{ 
  postprob = x$postprobs
  top.models = min(top.models, x$n.models)
  best = order(-x$postprobs)[1:top.models]
  postprob=postprob[best]/sum(postprob[best])
  which.mat <-  list2matrix.which(x, best)
  nvar <- ncol(which.mat)


  if (is.null(subset)) subset=1:nvar
  
  which.mat =  which.mat[,subset, drop=FALSE]
  nvar = ncol(which.mat)
  namesx = x$namesx[subset]

  scale = postprob
  prob.lab= "Posterior Probability"
  
  if (log)   {
    scale = log(postprob) - min(log(postprob)) 
    prob.lab="Log Posterior Odds"
  }

  if (intensity)  which.mat = sweep(which.mat, 1, scale+offset,"*")

  if (rotate) scale = rev(scale)

  if (prob) m.scale = cumsum(c(0,scale))
  else  m.scale = seq(0, top.models)

  mat = (m.scale[-1] +  m.scale[-(top.models+1)])/2
  
  colors = switch(color,
    "rainbow" = c("black", rainbow(top.models+1, start=.75, end=.05)),
    "blackandwhite" =  gray(seq(0, 1, length=top.models))
    )
  
  par.old = par()$mar

  if (rotate) {
      par(mar = c(6,6,3,5) + .1)
      image(0:nvar, mat, t(which.mat[top.models:1,]),
            xaxt="n", yaxt="n",
            ylab="",
            xlab="",
            zlim=c(0, max(which.mat)),
            col=colors, ...)
      
      axis(2,at=mat,labels=round(scale, digits=digits), las=plas, ...)
      axis(4,at=mat,labels=top.models:1, las=rlas, ...)
      mtext("Model Rank", side=4, line=3, las=0)
      mtext(prob.lab, side=2, line=4, las=0)
      axis(1,at=(1:nvar -.5), labels=namesx, las=vlas, ...) 
    }
  else{
    par(mar = c(6,8,6,2) + .1)
    image(mat, 0:nvar, which.mat[ , nvar:1],
          xaxt="n", yaxt="n",
          xlab="",
          ylab="",
          zlim=c(0, max(which.mat)),
          col=colors, ...)
    
    axis(1,at=mat,labels=round(scale, digits=digits), las=plas,...)
    axis(3,at=mat,labels=1:top.models, las=rlas, ...)
    mtext("Model Rank", side=3, line=3)
    mtext(prob.lab, side=1, line=4)
    axis(2,at=(1:nvar -.5), labels=rev(namesx), las=vlas, ...) 
  }

  box() 

  par(par.old)
  invisible()
} 
