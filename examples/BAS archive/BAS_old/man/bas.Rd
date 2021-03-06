\name{bas.lm}
\alias{bas}
\alias{bas.lm}
\title{Bayesian Adaptive Sampling Without Replacement for Variable
  Selection in Linear Models}
\description{Sample without replacement from a posterior distribution on models}
\usage{bas.lm(formula, data, n.models=NULL,  prior="ZS-null", alpha=NULL,
 modelprior=uniform(),
 initprobs="Uniform", method="BAS", update=NULL,
 bestmodel = NULL, bestmarg = NULL, prob.local = 0.0, prob.rw=0.5,
 Burnin.iterations = NULL, MCMC.iterations = NULL,
 lambda = NULL, delta = 0.025)
}
\arguments{
  \item{formula}{linear model formula for the full model with all
    predictors, Y ~ X.  All code assumes that an intercept will be
    included in each model and that the X's will be centered.}
  \item{data}{data frame}
  \item{n.models}{number of models to sample. If NULL, BAS will
    enumerate unless p > 25}
  \item{prior}{prior distribution for regression coefficients.  Choices include
    "AIC", "BIC", "g-prior", "ZS-null", "ZS-full", "hyper-g",
    "hyper-g-laplace", "EB-local", and "EB-global" }
 \item{alpha}{optional hyperparameter in g-prior or hyper g-prior.  For Zellner's
    g-prior, alpha = g, for the Liang et al hyper-g method, recommended
    choice is alpha are between (2, 4), with alpha = 3 recommended.}
  \item{modelprior}{Family of prior distribution on the models.  Choices
    include \code{\link{uniform}}
    \code{\link{Bernoulli}} or \code{\link{beta.binomial}}}
  \item{initprobs}{vector of length p with the initial  inclusion
    probabilities used for sampling without replacement (the intercwept
    should be included with probability one) or a character
    string giving the method used to construct the sampling probabilities
    if "Uniform" each predictor variable is equally likely to be
    sampled (equivalent to random sampling without replacement). If
    "eplogp", use the \code{\link{eplogprob}} function to aproximate the 
    Bayes factor to find initial marginal inclusion probabilitites and
    sample without replacement using these
    inclusion probabilaties. For variables that should always be
    included set the corresponding initprobs to 1. To run a
    Markov Chain to provide initial estimates of marginal
    inclusion probabilities, use method="MCMC+BAS" below.
  } 
  \item{method}{A character variable indicating which sampling method to
    use: method="BAS" uses Bayesian Adaptive Sampling (without
    replacement) using the sampling probabilities given in initprobs;
    method="MCMC+BAS" runs an initial MCMC to calculate marginal
    inclusion probabilities and then samples without replacement as in
    BAS; method = "AMCMC" runs an Adaptive MCMC (experimental).  For both
    BAS and AMCMC, the sampling probabilities can be updated as more
  models are sampled. (see  update below).  We recommend "MCMC+BAS" for
  high dimensional problems.}
  \item{update}{number of iterations between potential updates of the
    sampling probabilities. If NULL do not update, otherwise the
    algorithm will update using the marginal inclusion probabilities as
    they change while sampling takes place.  For large model spaces,
    updating is recommended. If the model space will be enumerated,
    leave at the default.}
  \item{bestmodel}{optional binary vector representing a model to
    initialize the sampling. If NULL sampling starts with the null
    model}
  \item{bestmarg}{optional value for the log marginal associated with
    the bestmodel}
  \item{prob.local}{A future  option to allow sampling of models
    "near" the median probability model.  Not used at
    this time.}
  \item{prob.rw}{For any of the MCMC methods, probability of using the
    random-walk proposal; otherwise use a random "flip" move to propose
    a new model.}
  \item{Burnin.iterations}{Number of iterations to discard when using any
    of the MCMC options}
   \item{MCMC.iterations}{Number of iterations to run  MCMC when MCMC
     options are used}
   \item{lambda}{Parameter in the AMCMC algorithm.}
   \item{delta}{truncation parameter to prevent sampling probabilities
     to degenerate to 0 or 1.}  }  \details{BAS provides several search
algorithms to find high probability models for use in Bayesian Model
Averaging or Bayesian model selection. For p less than 20-25, BAS can
enumerate all models depending on memory availability, for larger p, BAS
samples without replacement using random or deterministic sampling. The
Bayesian Adaptive Sampling algorithm of Clyde, Ghosh, Littman (2010)
samples models without replacement using the initial sampling
probabilities, and will optionally update the sampling probabilities
every "update" models using the estimated marginal inclusion
probabilties. BAS uses different methods to obtain the \code{initprobs},
which may impact the results in high-dimensional problems.
The
deterinistic sampler provides a list of the top models in order of an
approximation of independence using the provided \code{initprobs}.  This
may be effective after running the other algorithms to identify high
probability models and works well if 
the correlations of variables are small to modest.  The priors on
coefficients include Zellner's g-prior, the Hyper-g prior (Liang et al
2008, the Zellner-Siow Cauchy prior, Empirical Bayes (local and gobal)
g-priors.  AIC and BIC are also included.  } \value{
  \code{bas} returns an object of class \code{BMA}

An object of class \code{BMA} is a list containing at least the following components:

\item{postprob}{the posterior probabilities of the models selected}
\item{priorprobs}{the prior probabilities of the models selected}
  \item{namesx}{the names of the variables}
  \item{R2}{R2 values for the models}
  \item{logmarg}{values of the log of the marginal likelihood for the
    models}
 \item{n.vars}{total number of independent variables in the full model,
   including the intercept}
  \item{size}{the number of independent variables in each of the models,
    includes the intercept}
  \item{which}{a list of lists with one list per model with  variables
    that are included in the model} 
  \item{probne0}{the posterior probability that each variable is non-zero}
  \item{ols}{list of lists with one list per model giving the OLS
estimate of each (nonzero) coefficient for each model.  The intercept
is the mean of Y as each column of X has been centered by subtracting
its mean.}
  \item{ols.se}{list of lists with one list per model giving the OLS standard error of each coefficient for each model}
  \item{prior}{the name of the prior  that created the BMA object}
  \item{alpha}{value of hyperparameter in prior used to create the BMA
    object.}
  \item{modelprior}{the prior distribution on models that created the BMA object}
  \item{Y}{response}
  \item{X}{matrix of predictors}
  \item{mean.x}{vector of means for each column of X (used in \code{\link{predict.bma}})}
  
 The function  \code{\link{summary.bma}}, is used to print a summary of
 the results. The function \code{\link{plot.bma}} is used to plot
 posterior distributions for the coefficients and
 \code{\link{image.bma}} provides an image of the distribution over models.
 Posterior summaries of coefficients can be extracted using
 \code{\link{coefficients.bma}}.  Fitted values and predictions can be
 obtained using the functions  \code{\link{fitted.bma}} and \code{\link{predict.bma}}.
 BMA objects may be updated to use a different prior (without rerunning
 the sampler) using the function  \code{\link{update.bma}}.
}

\references{
  Clyde, M. Ghosh, J. and Littman, M. (2009) Bayesian Adaptive Sampling
  for Variable Selection and Model Averaging. Department of Statistical
  Science Discussion Paper 2009-16. Duke University.
  
  Clyde, M. and George, E. I. (2004) Model Uncertainty. Statist. Sci.,
  19, 81-94. \cr \url{http://www.isds.duke.edu/~clyde/papers/statsci.pdf}
  
  Clyde, M. (1999)
  Bayesian Model Averaging and Model Search Strategies (with
  discussion). In Bayesian Statistics 6. J.M. Bernardo, A.P. Dawid,
  J.O. Berger, and A.F.M. Smith eds. Oxford University Press, pages
  157-185.

  Hoeting, J. A., Madigan, D., Raftery, A. E. and Volinsky, C. T. (1999)
  Bayesian model averaging: a tutorial (with discussion). Statist. Sci.,
  14, 382-401. \cr \url{http://www.stat.washington.edu/www/research/online/hoeting1999.pdf}
  
  Liang, F., Paulo, R., Molina, G., Clyde, M. and  Berger,
  J.O. (2005) Mixtures of  g-priors for Bayesian Variable
  Selection. Journal of the American Statistical Association
  \cr \url{http://www.stat.duke.edu/05-12.pdf}
  
  Zellner, A. (1986) On assessing prior distributions and Bayesian
  regression analysis with g-prior distributions. In Bayesian Inference
  and Decision Techniques: Essays in Honor of Bruno de Finetti,
  pp. 233-243. North-Holland/Elsevier.
    
  Zellner, A. and Siow, A. (1980) Posterior odds ratios for selected
  regression hypotheses. In Bayesian Statistics: Proceedings of the First
  International Meeting held in Valencia (Spain), pp. 585-603.
}


\author{Merlise Clyde (\email{clyde@stat.duke.edu}) and Michael Littman}
  
\seealso{ \code{\link{summary.bma}},
          \code{\link{coefficients.bma}},
          \code{\link{print.bma}},
	  \code{\link{predict.bma}},
	  \code{\link{fitted.bma}}
          \code{\link{plot.bma}},
	  \code{\link{image.bma}},
	  \code{\link{eplogprob}},
	  \code{\link{update.bma}}
	  
}
	
\examples{
demo(BAS.hald)
\dontrun{demo(BAS.USCrime) }
}

\keyword{regression}


