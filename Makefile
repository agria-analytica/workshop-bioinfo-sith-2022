# Workshop Bioinformatika: Analisis Bioinformatik Dalam Pemuliaan Berbasis Moelkuler 
# Topik: Whole Genome Assembly
# Sekolah Ilmu dan Teknologi Hayati
# Institut Teknologi Bandung
# 8-10 Agustus 2022

SHELL = /bin/bash
DOCKER = docker run --rm -v $$(pwd):/project -w /project
DOCKER_FASTQC = $(DOCKER) agria.analytica/fastqc:0.11.9 
DOCKER_KMC = $(DOCKER) agria.analytica/kmc:3.1.2rc1
DOCKER_TRIMMOMATIC = $(DOCKER) agria.analytica/trimmomatic:0.38
DOCKER_GATB_MINIA = docker run --rm -v $$(pwd):/tmp/project -w /tmp/project agria.analytica/gatb-minia:9d56f42  
DOCKER_QUAST = $(DOCKER) agria.analytica/quast:5.0.2
DOCKER_GENOMESCOPE = $(DOCKER) agria.analytica/genomescope2:2.0
CORES = 2

# membuat struktur folder untuk analisis.
DIRS = data \
	   results results/fastqc results/trimmomatic results/gatb-minia results/quast \
			   results/kmc results/kmc/temp results/genomescope \
	   bin

$(DIRS):
	[ -d $@ ] || mkdir $@

# instalasi program menggunakan platform docker.
instal-program: $(DIRS) bin/fastqc.ok bin/kmc.ok bin/trimmomatic.ok bin/quast.ok bin/genomescope2.ok bin/gatb-minia.ok

bin/fastqc.ok:
	docker build -t agria.analytica/fastqc:0.11.9 -f bin/fastqc.dockerfile . && \
	touch $@

bin/kmc.ok:
	docker build -t agria.analytica/kmc:3.1.2rc1 -f bin/kmc.dockerfile . && \
	touch $@

bin/trimmomatic.ok:
	docker build -t agria.analytica/trimmomatic:0.38 -f bin/trimmomatic.dockerfile . && \
	touch $@

bin/quast.ok:
	docker build -t agria.analytica/quast:5.0.2 -f bin/quast.dockerfile . && \
	touch $@

bin/genomescope2.ok:
	docker build -t agria.analytica/genomescope2:2.0 -f bin/genomescope2.dockerfile . && \
	touch $@

bin/gatb-minia.ok:
	docker build -t agria.analytica/gatb-minia:9d56f42 -f bin/gatb-minia.dockerfile . && \
	touch $@

# unduh data menggunakan wget.
SRA = ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR104/093/SRR10418193/SRR10418193.fastq.gz
ACULY_GENOME = https://bioinformatics.psb.ugent.be/gdb/aculops/Aculy_genome.tfa.gz
ACULY_ANNOTATION = https://bioinformatics.psb.ugent.be/gdb/aculops/Aculy_gff3_20200924.tar.gz
DATA = data/SRR10418193.fastq.gz
DATA_ACULY_GENOME = data/Aculy_genome.tfa
DATA_ACULY_ANNOTATION = data/Aculy_gff3_20200924.gff3


unduh-data: $(DIRS) $(DATA) $(DATA_ACULY_GENOME) $(DATA_ACULY_ANNOTATION) 

$(DATA): 
	wget -P $(dir $@) $(SRA)

$(DATA_ACULY_GENOME): 
	wget -P $(dir $@) $(ACULY_GENOME) && \
	gunzip -d $@.gz

$(DATA_ACULY_ANNOTATION): 
	wget -P $(dir $@) $(ACULY_ANNOTATION) && \
	tar -xvzf $(basename $@).tar.gz -C data && \
	cat $(dir $@)/scaffold*.gff3 > $@

# quality control reads sekuensing menggunakan fastqc.
DATA_TRIMMED = results/trimmomatic/$(basename $(basename $(notdir $(DATA)))).trimmed.fastq.gz
FASTQC_BEFORE = $(addprefix results/fastqc/, $(addsuffix _fastqc.html, $(basename $(basename $(notdir $(DATA))))))
FASTQC_AFTER = $(addprefix results/fastqc/, $(addsuffix _fastqc.html, $(basename $(basename $(notdir $(DATA_TRIMMED))))))

data-qc: $(DIRS) $(FASTQC_BEFORE) $(DATA_TRIMMED) $(FASTQC_AFTER)
	
$(FASTQC_BEFORE): $(DATA)
	@echo ""
	@echo "Quality control untuk data $(notdir $<) menggunakan FASTQC."
	$(DOCKER_FASTQC) fastqc -t $(CORES) -o $(dir $@) $<

$(DATA_TRIMMED): $(DATA)
	@echo ""
	@echo "Quality trimming reads dari data $(notdir $<) menggunakan Trimmotatic."
	$(DOCKER_TRIMMOMATIC) trimmomatic SE -threads $(CORES) $< $@ SLIDINGWINDOW:4:20 MINLEN:50 

$(FASTQC_AFTER): $(DATA_TRIMMED)
	@echo ""
	@echo "Quality control untuk data $(DATA) setelah trimming menggunakan Trimmomatic."
	$(DOCKER_FASTQC) fastqc -t $(CORES) -o $(dir $@) $<

# prediksi ukuran genom mengunakan distribusi kmer.
KMC_DATA_TRIMMED = results/kmc/$(notdir $(basename $(DATA_TRIMMED))).k21.kmc_pre
KMC_HIST_DATA_TRIMMED = results/kmc/$(notdir $(basename $(KMC_DATA_TRIMMED))).hist
GENOMESCOPE_DATA_TRIMMED = results/genomescope/A.lycopersici.k21.p2_linear_plot.png \
						   results/genomescope/A.lycopersici.k21.p3_linear_plot.png \
						   results/genomescope/A.lycopersici.k21.p4_linear_plot.png

analisis-kmer: $(DIRS) $(GENOMESCOPE_DATA_TRIMMED)

results/genomescope/A.lycopersici.k21.p2_linear_plot.png: $(KMC_HIST_DATA_TRIMMED)
	@echo ""
	@echo "Analisis distribusi kmer pada file $< dengan model diploid menggunakan genomescope2."
	$(DOCKER_GENOMESCOPE) genomescope2 -i $< -o $(dir $@) -k 21 -n $(firstword $(subst _, ,$(notdir $@))) -p 2 --kmercov 5

results/genomescope/A.lycopersici.k21.p3_linear_plot.png: $(KMC_HIST_DATA_TRIMMED)
	@echo ""
	@echo "Analisis distribusi kmer pada file $< dengan  model triploid menggunakan genomescope2."
	$(DOCKER_GENOMESCOPE) genomescope2 -i $< -o $(dir $@) -k 21 -n $(firstword $(subst _, ,$(notdir $@))) -p 3 --kmercov 5

results/genomescope/A.lycopersici.k21.p4_linear_plot.png: $(KMC_HIST_DATA_TRIMMED)
	@echo ""
	@echo "Analisis distribusi kmer pada file $< dengan model tetraploid menggunakan genomescope2."
	$(DOCKER_GENOMESCOPE) genomescope2 -i $< -o $(dir $@) -k 21 -n $(firstword $(subst _, ,$(notdir $@))) -p 4 --kmercov 5

$(KMC_HIST_DATA_TRIMMED): $(KMC_DATA_TRIMMED)
	@echo ""
	@echo "Memulai analisis distribusi kmer pada k=21 untuk file $< menggunakan kmc."
	$(DOCKER_KMC) kmc_tools transform $(basename $<) histogram $@ -cx10000	
	
$(KMC_DATA_TRIMMED): $(DATA_TRIMMED)
	@echo ""
	@echo "Memulai analisis kmer pada k=21 untuk file $< menggunakan kmc."
	$(DOCKER_KMC) kmc -k21 -t$(CORES) -m4 -ci3 -cs10000 $< $(basename $@) results/kmc/temp

# de novo whole genome assembly genom Aculops lycopersici menggunakan GATB Minia pipeline.
GATB_MINIA_DRAFT = results/gatb-minia/A.lycopersici.assembly.fasta

genome-assembly: $(GATB_MINIA_DRAFT)
	
$(GATB_MINIA_DRAFT): $(DATA_TRIMMED)
	@echo ""
	@echo "Memulai de novo genome assembly dengan kmer=21-181 menggunakan GATB Minia pipeline."
	$(DOCKER_GATB_MINIA) /bin/bash -c "cd $(dir $@) && ../../../gatb -s ../../$< -o $(notdir $(basename $@)) --nb-cores $(CORES)"

# evaluasi hasil whole genome assembly dengan berbagai ukuran kmer menggunakan quast.
ASSEMBLY = results/gatb-minia/A.lycopersici.assembly_k21.contigs.fa \
		   results/gatb-minia/A.lycopersici.assembly_k41.contigs.fa \
		   results/gatb-minia/A.lycopersici.assembly_k61.contigs.fa \
		   results/gatb-minia/A.lycopersici.assembly_k81.contigs.fa \
		   results/gatb-minia/A.lycopersici.assembly_k101.contigs.fa \
		   results/gatb-minia/A.lycopersici.assembly_k121.contigs.fa \
		   results/gatb-minia/A.lycopersici.assembly_k141.contigs.fa \
		   results/gatb-minia/A.lycopersici.assembly_k181.contigs.fa \
		   results/gatb-minia/A.lycopersici.assembly.fasta
ASSEMBLY_NAME = k21,k41,k61,k81,k101,k121,k141,k181,k181-scaffold

evaluasi-assembly: results/gatb-minia/A.lycopersici.assembly.fasta $(DATA_ACULY_GENOME) $(DATA_ACULY_ANNOTATION)
	@echo ""
	@echo "Memulai evaluasi hasil assembly pada berbagai ukuran kmer."
	$(DOCKER_QUAST) quast.py -o results/quast -t $(CORES) -r $(DATA_ACULY_GENOME) \
	--features $(DATA_ACULY_ANNOTATION) -l $(ASSEMBLY_NAME) --min-contig 500 $(ASSEMBLY)







