% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dates.R
\name{sircovid_date}
\alias{sircovid_date}
\alias{sircovid_date_as_date}
\alias{as_sircovid_date}
\alias{as_date}
\title{Date handling for sircovid}
\usage{
sircovid_date(date)

sircovid_date_as_date(date)

as_sircovid_date(date)

as_date(date)
}
\arguments{
\item{date}{A Date object, or something that can be converted to
one, or a "sircovid date"; see Details}
}
\value{
An integer, being the number of days into 2020
}
\description{
We need to map "dates" onto \code{\link[dust:dust]{dust::dust}}'s concept of model
"step" and we do this by mapping a date such as \code{2020-03-02} into
the number of days into 2020 (62 here, with the 1st of January
being day 1). We call this integer number a "sircovid date".
}
\details{
There are several related functions here
\itemize{
\item \code{sircovid_date} converts its argument into an R \code{Date} object,
then applies this tranformation. If the argument is not a \code{Date}
object or a string representing one, an error will be thrown.
\item \code{sircovid_date_to_date} does the reverse conversion to
\code{sircovid_date}, converting an integer sircovid date into an R
\code{Date}
\item \code{as_sircovid_date} does the same conversion as \code{sircovid_date}
but will assume that an integer \emph{already} represents a sircovid
date and will return it unmodified rather than erroring.
\item \code{as_date} does a string to date conversion, using \code{\link[=as.Date]{as.Date()}}
but requiring the dates are in ISO 8601 (YYYY-MM-DD) format (it
is a helper that avoids conversion to \code{NA}, instead throwing an
error)
}
}
\examples{
# Convert dates into sircovid dates:
sircovid::sircovid_date("2020-01-01")
sircovid::sircovid_date(c("2020-03-01", "2020-10-01"))

# Reverse the conversion:
sircovid::sircovid_date_as_date(1)
sircovid::sircovid_date_as_date(c(61, 275))

# Double conversion not possible with sircovid_date...
try(sircovid::sircovid_date(61))
# ...but allowed with as_sircovid_date
sircovid::as_sircovid_date(61)

# Strict date conversion with as_date
sircovid::as_date("2020-03-01")
try(sircovid::as_date("03-01-2020"))
}
