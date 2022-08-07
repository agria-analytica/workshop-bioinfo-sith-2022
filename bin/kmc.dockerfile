FROM mambaorg/micromamba:0.15.3
RUN micromamba install -y -n base kmc=3.1.2rc1 -c bioconda -c conda -c conda-forge -c defaults && \
	micromamba clean --all --yes
