# generate the main results: flowSegmentResult.RData
# dependencies: gpu raw results.
# next: plot.
# auto source:?

#### load data ---------------------------------------------------------------------------------------------------------------
setwd("D:/hNow/Dropbox/phd/gpu/gpu-r-proj")
source('./339_exp1RestEnv.R')
Sys.setenv(TZ="UTC")

library(data.table)
library(ggplot2)

# param @ flow / time of day -------------------------------------------------------------------------------
if(not.exists('analysisSetup')){analysisSetup = NULL}
flowSegmentResult = NULL

pFile = file('gpu_raw_results.bin', "rb")
t = readBin(pFile, n = file.size('gpu_raw_results.bin')/4, single(), size = 4, endian = "little")
close(pFile)

# index in pd_weightListing: [flowIsGoingDown][flowIndicatorIndex][pred-h][search-h = 0][win = 0][k1 = 0]
if(1 != length(t)/(algorithmSetup$combinationNrPerTimePointNoPrediction * algorithmSetup$flowSegmentNr * length(algorithmSetup$predictStepLengthListing))){
    stop('WeightNr wrong: gpu_raw_results.bin')
}
weightListing = t

# gen param combinations using "repeat"
t = expand.grid(k1 = algorithmSetup$kLevel1Listing, v = algorithmSetup$windowSizeListing, d = algorithmSetup$searchStepLengthListing)
t = as.data.table(t)
analysisSetup$paramCombination = t

analysisSetup$flowIndicatorIndexNr = 10
analysisSetup$perTimePoint_combinationNr = algorithmSetup$combinationNrPerTimePoint
for(flowIsGoingDown in c(0,1)){
    for(flowIndicatorIndex in 0:(algorithmSetup$flowIndicator_segmentNr - 1)){
        for(predictStepLengthIndex in 0:(length(algorithmSetup$predictStepLengthListing) - 1)){
            weightIndexStart = (flowIsGoingDown*analysisSetup$flowIndicatorIndexNr + flowIndicatorIndex)*analysisSetup$perTimePoint_combinationNr + predictStepLengthIndex * algorithmSetup$combinationNrPerTimePointNoPrediction;
            weightOrderStart = weightIndexStart + 1
            weightOrderEnd = weightOrderStart + algorithmSetup$combinationNrPerTimePointNoPrediction - 1
            weight = weightListing[weightOrderStart:weightOrderEnd]
            weight = data.table(weight)
            setnames(weight, "weight")
            mainDt = analysisSetup$paramCombination
            #mainDt[, names(mainDt) := lapply(.SD, function(x) x*weight)]
            for(columnIndex in 1:ncol(mainDt)){
                mainDt[[columnIndex]] = mainDt[[columnIndex]] * weight
            }
            t = data.table(mainDt[, lapply(.SD, sum)])
            t$flowIsGoingDown = flowIsGoingDown
            t$flowIndicatorIndex = flowIndicatorIndex
            t$m = algorithmSetup$predictStepLengthListing[predictStepLengthIndex + 1]
            flowSegmentResult <<- rbind(flowSegmentResult, t)
        }
    }
}
flowSegmentResult
save(flowSegmentResult, file = 'flowSegmentResult.RData')
