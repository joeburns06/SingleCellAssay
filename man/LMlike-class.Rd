% Generated by roxygen2 (4.0.1): do not edit by hand
\docType{class}
\name{LMlike-class}
\alias{LMlike-class}
\title{Linear Model-like Class}
\description{
Wrapper around modeling function to make them behave enough alike that Wald tests and Likelihood ratio are easy to do.
To implement a new type of zero-inflated model, extend this class.
}
\section{Slots}{

\describe{
\item{design}{a data.frame from which variables are taken for the right hand side of the regression}
\item{fitC}{The continuous fit}
\item{fitD}{The discrete fit}
\item{response}{The left hand side of the regression}
\item{fitted}{A \code{logical} with components "C" and "D", TRUE if the respective component has converge}
\item{formula}{A \code{formula} for the regression}
\item{fitArgsC}{}
\item{fitArgsD}{Both \code{list}s giving arguments that will be passed to the fitter (such as convergence criteria or case weights)}
}
}
\seealso{
fit

coef

lrTest

waldTest

vcov

dof

logLik
}

