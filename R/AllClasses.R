##' @import Biobase
##' @import BiocGenerics
##' @importFrom plyr rbind.fill
##' @import methods
NULL

##' DataLayer class
##' 
##' DataLayer is a 3-D array, wrapped to make it look like a matrix.
##' It is used to hold matrix-like expression data, for which we might want to keep several representations (transformations) around.
##' The number of matrix "layers" is given by the trailing dimension.
##' Dimensions 1 and 2 correspond to the "rows" and "columns" of the matrix.
##' The layer that is active can be set, and additional layers created (concatenated).
##' }
##' \section{Slots}{
##' DataLayer extends array, and has the following additional slots
##' \describe{
##'   \item{.Data}{the underlying array}
##'   \item{valid}{a \code{logical} that may optionally indicate the freshness of derived layers (if the underlying data changes).  Not currently used.}
##'   \item{layer}{which 'slice' of the array is being used}
##' }}
##' \section{Methods}{
##' \describe{
##' \item{addlayer}{Concatentate another slice onto the object}
##' \item{layername}{Return the name of the current slice}
##' \item{layer}{Return the active layer}
##' \item{layer<-}{Set the active layer}
##' \item{exprs}{Return the matrix representation of the active layer}
##' \item{exprs<-}{Replace the matrix on the current layer.}
##' }
##' @examples
##' ar <- array(1:10, dim=c(2, 5, 1))
##' dl <- new('DataLayer', .Data=ar)
##' nrow(dl) #2
##' ncol(dl) #5
##' layer(dl)
##' dl <- addlayer(dl, 'negative')
##' ex <- exprs(dl)
##' layer(dl) <- 'negative' #or could use 2
##' exprs(dl)<- -ex
##' exprs(dl)
##' @name DataLayer-class
##' @docType class 
##' @aliases DataLayer
##' @seealso \code{\link{SingleCellAssay}}, \code{\link{SingleCellAssay-class}}
setClass('DataLayer', contains='array', representation=representation(layer='numeric', valid='logical'), prototype=prototype(array(NA, dim=c(0, 0, 1)), layer=1L, valid=TRUE), validity=function(object){
  #cat('DL dim ', dim(object@.Data), '\n')
  length(dim(object@.Data))==3
  })

setClass('Mapping', contains='list')
setMethod('initialize', 'Mapping', function(.Object, keys=NULL, values=NULL, ...){
  .Object <- callNextMethod()
  if(!is.null(keys)){
    if(is.null(values)) values <- rep(NA, length(keys))
    if(!is.character(keys)) stop('keys must be character')
    .Object@.Data <- vector(mode='list', length=length(keys))
    names(.Object@.Data) <- keys
    for(i in seq_along(.Object@.Data)) .Object@.Data[[i]] <- values[[i]]
  }
  
  .Object
})

setMethod('show', 'Mapping', function(object){
  cat(class(object), ' containing : ', names(object), '\n')
})


##' Vbeta Data Set
##' @docType data
##' @name vbeta
##' @rdname vbeta-dataset
##' @format a data frame with 11 columns.
##' Column \code{Ct} contains the cycle threshold, with NA denoting that the threshold was never crossed.  So it is inversely proportional to the log2 mRNA, and should be negated (and NAs set to zero) if it is used as a expression measurement for a \code{FluidigmAssay}.
NULL


##' Vbeta Data Set, FluidigmAssay
##' @docType data
##' @name vbetaFA
##' @rdname vbetaFA-dataset
##' @format a \code{FluidigmAssay} of the vbeta data set.
##' @seealso \code{\link{vbeta}}, \code{\link{FluidigmAssay}}
NULL

Mandatory_Featurevars <- NULL#c('primerid')
Mandatory_Cellvars <- NULL#c('wellKey')



SingleCellAssayValidity <- function(object){
  ##message('SingleCellAssayValidity') #DEBUG
  if(nrow(cData(object))==0 || nrow(fData(object) == 0)) return(TRUE)
  if(nrow(object)!=nrow(cData(object))){
    message('dimension mismatch between cData and nrows')
    return(FALSE)
    }
  if(ncol(object)!=nrow(fData(object))){
    message('dimension mismatch between fData and ncols')
    return(FALSE)
  }

  if(!all(fData(object)$primerid == colnames(object))){
    message("'DataLayer' column names mismatch featureData 'primerid' field")
    return(FALSE)
  }
  
  if(!all(cData(object)$wellKey == row.names(object))){
    message("'DataLayer' row names mismatch cellData 'wellKey' field")
    return(FALSE)
  }
  
  if(!all(names(object@cmap) %in% names(cData(object)))){
    message('some expected fields in cData are missing')
    return(FALSE)
  }
  if(!all(names(object@fmap) %in% names(fData(object)))){
    message('some expected fields in fData are missing')
    return(FALSE)
  }
  TRUE                                  #this stuff might not belong in the validity, it's getting called too early when subclasses of SingleCellAssay are constructed
}
                                          

##' SingleCellAssay class
##' 
##' SingleCellAssay represents an arbitrary single cell assay
##' It is meant to be flexible and is subclassed to represent specific assay
##' types like Fluidigm and NanoString. It should be constructed using the \code{SingleCellAssay}, \code{SCASet} or subclass constructors.
##' mapNames for the SingleCellAssay class are in the object \code{SingleCellAssay:::Mandatory_Cellvars}
##' mapNames for the FluidigmAssay class are in the object \code{SingleCellAssay:::FluidigmMapNames}
##' }
##' \section{Slots}{
##' SingleCellAssay extends class \code{\link{DataLayer}}, so inherits its slots and methods.  It also contains the following additional slots:
##' \describe{
##'   \item{featureData}{an \code{AnnotatedDataFrame} that describes feature-level metadata (i.e. genes)}
##'   \item{phenoData}{an \code{AnnotatedDataFrame} that describes the phenotype-level metadata (i.e. subject or experimental unit)} (not yet implemented)
##'   \item{cellData}{an \code{AnnotatedDataFrame} that describes the cell-level metadata (i.e. per individual cell)}
##'   \item{description}{a \code{data.frame}}
##'   \item{id}{a vector of type \code{character} that identifies the set of columns acting as a primary key to uniquely identify a single-cell or single-well across all wells / cells / assays / subjects / conditions in the data set.}
##' }
##' @name SingleCellAssay-class
##' @docType class 
##' @aliases SingleCellAssay-class
##' @aliases FluidigmAssay-class
##' @aliases NanoStringAssay-class
##' @aliases show,SingleCellAssay-method
##' @rdname SingleCellAssay-class
##' @seealso \code{\link{SingleCellAssay}}, \code{\link{NanoStringAssay}}, \code{\link{FluidigmAssay}}, \code{\link{DataLayer}}
setClass("SingleCellAssay",contains="DataLayer",
         representation=representation(featureData="AnnotatedDataFrame",
           phenoData="AnnotatedDataFrame",
           cellData="AnnotatedDataFrame",
           description='data.frame',
           id="ANY",
           cmap='Mapping', fmap='Mapping',
           keep.names='logical'),
         prototype=prototype(phenoData=new("AnnotatedDataFrame"),
           featureData=new("AnnotatedDataFrame"),
           cellData=new("AnnotatedDataFrame"),
           description=data.frame(),
           id=numeric(0),
           cmap=new('Mapping', keys=Mandatory_Cellvars),
           fmap=new('Mapping', keys=Mandatory_Featurevars),
           keep.names=TRUE),
         validity=SingleCellAssayValidity)


## Same as SingleCellAssay, but with additional mapNames
FluidigmMapNames <- c(Mandatory_Cellvars, 'ncells')

setClass('FluidigmAssay', contains='SingleCellAssay', prototype=prototype(cmap=new('Mapping', keys=FluidigmMapNames)),validity=SingleCellAssayValidity)

#Could write a constructor that takes a post-processing function...
setClass('NanoStringAssay', contains='FluidigmAssay',validity=SingleCellAssayValidity)


##'Holds output and diagnostics from thresholdNanoString
##'Not intended to be called by the user.
##' 
##' @section Slots:
##' \describe{
##' \item{melted}{A \code{data.frame} containing a melted version of \code{nsa}, plus the columns 'ps', giving the probability that a measurement belongs to the signal cluster, 'clusterID' the inferred cluster}
##' \item{nsa}{The thresholded \code{NanoStringAssay} with the thresholded expression in layer \code{et}}
##' \item{densities}{A \code{list} of length \code{ncol(nsa)} of marginal (mixture model) densities of each gene.}
##' \item{means}{A \code{matrix} dimension \code{ncol(nsa)} \eqn{\times} 2 given the posterior mean of each cluster.}
##' \item{props}{A \code{matrix} dimension \code{ncol(nsa)} \eqn{\times} 2 given the posterior probability of each cluster.}
##' \item{startLayer}{A \code{character} giving the initial layer that was used to generate the thresholding}
##' }
##' @seealso thresholdNanoString
##' @docType class
setClass('ThresholdedNanoString', representation=representation(melted='data.frame', nsa='NanoStringAssay', densities='list', means='matrix', props='matrix', startLayer='character'))



##'RNASeqAssay class. Doesn't require ncells
##'@exportClass RNASeqAssay
setClass('RNASeqAssay',contains='SingleCellAssay', prototype=prototype(cmap=new('Mapping',keys=Mandatory_Cellvars)),validity=SingleCellAssayValidity)

##'SCASet is a set of SingleCellAssay objects or objects of its subclasses (i.e. FluidigmAssay)
##'The constructor \code{SCASet} should be used to make objects of this class.
##' }
##' \section{Slots}{
##' \describe{
##' \item{set}{A \code{list} of \code{SingleCellAssays} or its subclasses}
##' }
##' 
##' @rdname SCASet-class
##' @docType class
##' @name SCASet-class
##' @exportClass SCASet
##' @aliases SCASet-class
setClass("SCASet",
         representation=list(set="list"),validity=function(object){
           if(all(names(object@set)!=unlist(lapply(object@set,function(x) x@id),use.names=FALSE))){
             warning("Names of the SCASet don't match the SingleCellAssay id's. Plese use the SingleCellAssay() constructor.")
             return(FALSE)
           }
           return(TRUE)
         })


## Classes
##' Linear Model-like Class
##'
##' Wrapper around modeling function to make them behave enough alike that Wald tests and Likelihood ratio are easy to do.
##' To implement a new type of zero-inflated model, extend this class.
##'
##' @section Slots:
##' \describe{
##' \item{design}{a data.frame from which variables are taken for the right hand side of the regression}
##' \item{fitC}{The continuous fit}
##' \item{fitD}{The discrete fit}
##' \item{response}{The left hand side of the regression}
##' \item{fitted}{A \code{logical} with components "C" and "D", TRUE if the respective component has converge}
##' \item{formula}{A \code{formula} for the regression}
##' \item{fitArgsC}{}
##' \item{fitArgsD}{Both \code{list}s giving arguments that will be passed to the fitter (such as convergence criteria or case weights)}
##' }
##' @seealso fit
##' @seealso coef
##' @seealso lrTest
##' @seealso waldTest
##' @seealso vcov
##' @seealso dof
##' @seealso logLik
##' @name LMlike-class
##' @docType class
setClass('LMlike', slots=c(design='data.frame', fitC='ANY', fitD='ANY', response='ANY', fitted='logical', formula='formula', fitArgsD='list', fitArgsC='list'),     prototype=list(fitted =c(C=FALSE, D=FALSE), formula=formula(0~0)), validity=function(object){
    stopifnot( all(c("C", "D") %in% names(object@fitted)))
    if(length(object@response)>0 && any(is.na(object@response))) stop('NAs not permitted in response')
})

setClass('GLMlike', contains='LMlike', slots=c(modelMatrix='matrix'), validity=function(object){
    if(length(object@response)>0){
        stopifnot(length(object@response)==nrow(object@design))
        #stopifnot(length(object@response)==nrow(object@modelMatrix))
    }},
    prototype=list(modelMatrix=matrix(nrow=0, ncol=0)))

setClass('BayesGLMlike', contains='GLMlike')
setClass('LMERlike', contains='LMlike')
setClass('ShrunkenGLMlike', contains='GLMlike', slots=c(priorVar='numeric', priorDOF='numeric'), prototype=list(priorVar=0, priorDOF=0))


##' SingleCellAssay: A constructor for an object of type SingleCellAssay.
##'
##' This is the constructor for the class. This class intends to ease the analysis of single cell assays, in which multiple, exchangeable, cells from an experimental unit (patient, or organism) are assayed along several (or many) dimensions, such as genes. A few examples of this might be Fluidigm gene expression chips, or single cell sequencing experiments.  The chief functionality is to make it easy to keep cellular-level metadata linked to the measurements through \code{cellData} and \code{phenoData}.  There are also subsetting and splitting measures to coerce between a SingleCellAssay, and a \link{SCASet}.
##' @param dataframe A 'flattened' \code{data.frame} or \code{data.table} containing columns giving cell and feature identifiers and  a measurement column
##' @param idvars character vector naming columns that uniquely identify a cell
##' @param primerid character vector of length 1 that names the column that identifies what feature (i.e. gene) was measured
##' @param measurement character vector of length 1 that names the column containing the measurement 
##' @param id An identifier (eg, experiment name) for the resulting object
##' @param cellvars Character vector naming columns containing additional cellular metadata
##' @param featurevars Character vector naming columns containing additional feature metadata
##' @param phenovars Character vector naming columns containing additional phenotype metadata
##' @param ... additional arguments are ignored
##' @export SingleCellAssay
##' @aliases SingleCellAssay
##' @name SingleCellAssay
##' @seealso \code{\link{FluidigmAssay}}
##' @docType methods
##' @examples
##' ## See FluidigmAssay for examples
##' \dontrun{example(FluidigmAssay)}
##' @return SingleCellAssay object
SingleCellAssay<-function(dataframe=NULL,idvars=NULL,primerid=NULL,measurement=NULL,id=numeric(0), cellvars=NULL, featurevars=NULL, phenovars=NULL, ...){
  new('SingleCellAssay', dataframe=dataframe, idvars=idvars, primerid=primerid, measurement=measurement, id=id, cellvars=cellvars, featurevars=featurevars, phenovars=phenovars)
}

##' Constructor for a FluidigmAssay
##'
##' Constructs a FluidigmAssay object. Differs little from the SingleCellAssay constructor. Only the \code{ncells} parameter is additionally required.
##' @inheritParams SingleCellAssay
##' @param ncells A \code{character} specifying the column which gives the number of cells per well
##' @return A FluidigmAssay object
##' @author Andrew McDavid and Greg Finak
##' @examples
##' data(vbeta)
##' colnames(vbeta)
##' vbeta <- computeEtFromCt(vbeta)
##' vbeta.fa <- FluidigmAssay(vbeta, idvars=c("Subject.ID", "Chip.Number", "Well"), primerid='Gene', measurement='Et', ncells='Number.of.Cells', geneid="Gene",  cellvars=c('Number.of.Cells', 'Population'), phenovars=c('Stim.Condition','Time'), id='vbeta all')
##' show(vbeta.fa)
##' nrow(vbeta.fa)
##' ncol(vbeta.fa)
##' head(fData(vbeta.fa)$primerid)
##' table(cData(vbeta.fa)$Subject.ID)
##' vbeta.sub <- subset(vbeta.fa, Subject.ID=='Sub01')
##' show(vbeta.sub)
##' @export
FluidigmAssay<-function(dataframe=NULL,idvars,primerid,measurement, ncells, geneid=NULL,id=numeric(0), cellvars=NULL, featurevars=NULL, phenovars=NULL, ...){
  cmap <- new('Mapping', .Data=list('ncells'=ncells))
    new('FluidigmAssay', dataframe=dataframe, idvars=idvars, primerid=primerid, measurement=measurement, id=id, cellvars=cellvars, featurevars=featurevars, phenovars=phenovars, cmap=cmap)
}

##' Constructs a SCASet
##'
##' An SCASet is a list of SingleCellAssays or objects inheriting from SingleCellAssay. The type of constructor called is determined by the value of contentClass, which should be the class of the SCA inheriting object contained in this SCASet. Both the class and the constructor should exist and have the same name. The code dynamically looks to see if the a function with the same name exists, and ASSUMES it is the constructor for the class.
##' ##' ##' TODO SCASet constructor should perhaps take a SingleCellAssay class or FluidigmClass rather than a dataframe. Then we can learn the class type for construction.
##' @title SCASet constructor
##' @param dataframe flat data.frame ala SingleCellAssay
##' @param splitby either a character vector naming columns or a factor or a list of factors used to split dataframe into SingleCellAssays
##' @param idvars character vector naming columns that uniquely identify a cell
##' @param primerid character vector of length 1 that names the column that containing what feature was measured
##' @param measurement character vector of length 1 that names the column containing the measurement
##' @param contentClass a character, the name of the class being constructed within this SCASet. Defaults to SingleCellAssay. Other methods may pass in other classes, i.e. FluidigmAssay.
##' @param ... passed up to SingleCellAssay or other dynamically called constructor.
##' @return SCASet
##' @note The dynamic lookup of the constructor could be made more robust. 
##' @aliases SCASet
##' @rdname SCAset-methods
##' @export 
SCASet<-function(dataframe,splitby,idvars=NULL,primerid=NULL,measurement=NULL,contentClass="SingleCellAssay",...){
  if(is.character(splitby) && all(splitby %in% names(dataframe))){
  spl<-split(dataframe,dataframe[, splitby])
} else if(is.factor(splitby) || is.list(splitby) || is.character(splitby)){
  spl <- split(dataframe, splitby)
} else{
  stop("Invalid 'splitby' specification")
}
 
  set<-vector("list",length(spl))
  names(set)<-names(spl)
  for(i in seq_along(set)){
    ##construct a call using contentClass
    F <- try(getFunction(contentClass),silent=TRUE)
    if(is(F,"try-error"))
      message("Can't construct a class of type ",contentClass[[1]],". Constructor of this name doesn't exist")
      cl<-as.call(list(as.name(contentClass[[1]]),dataframe=spl[[i]],idvars=idvars,primerid=primerid,id=names(spl)[[i]], measurement=measurement,...))
    set[[i]]<-eval(cl)
  }
  new("SCASet",set=set)
}
