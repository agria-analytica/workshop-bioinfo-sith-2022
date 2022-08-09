FROM mambaorg/micromamba:0.15.3
RUN micromamba install -y -n base minimap2=2.24 -c bioconda -c conda -c conda-forge -c defaults && \
	micromamba clean --all --yes
