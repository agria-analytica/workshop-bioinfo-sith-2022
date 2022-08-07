FROM mambaorg/micromamba:0.15.3
RUN micromamba install -y -n base fastqc=0.11.9 -c bioconda -c conda -c conda-forge -c defaults && \
	micromamba clean --all --yes
