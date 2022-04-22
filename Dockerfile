# syntax=docker/dockerfile:1.2
FROM bitnami/git as git
RUN git clone https://github.com/cms-opendata-analyses/HiggsExample20112012.git

FROM --platform=linux/amd64 cmssw_5_3_32-slc6_amd64_gcc472 as builder
SHELL ["/bin/bash", "-c"]
RUN source /cvmfs/cms.cern.ch/cmsset_default.sh && \
    scramv1 project CMSSW_5_3_32 && \
    cd CMSSW_5_3_32/src && \
    eval `scramv1 runtime -sh`
COPY --from=git --chown=cmsusr:cmsusr /HiggsExample20112012 ${HOME}/CMSSW_5_3_32/src/HiggsExample20112012
RUN source /cvmfs/cms.cern.ch/cmsset_default.sh && \
    cd ${HOME}/CMSSW_5_3_32/src && \
    eval `scramv1 runtime -sh` && \
    scram b

FROM --platform=linux/amd64 gitlab-registry.cern.ch/cms-cloud/cmssw-docker/slc6-cvmfs
COPY --from=builder /home/cmsusr/CMSSW_5_3_32/ /home/cmsusr/CMSSW_5_3_32/