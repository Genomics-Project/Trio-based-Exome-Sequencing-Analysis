# Trio-Based Exome Analysis: Collaborative Diagnostic Pipeline
## 🔍 Investigators:
Anna Giambelli & Davide La Canna
## 🎓 Institutions: 
Università degli Studi di Milano, Politecnico di Milano (PoliMi)
## 📅 Date: 
April 2026

## 📎 Project Overview
This repository hosts a collaborative bioinformatic study focused on identifying pathogenic variants in 10 simulated family trios. To ensure clinical-grade reproducibility and organization, the repository is divided by investigator, each managing 5 distinct trios with specific inheritance models.
## 📁 Repository Architecture
```plaintext
.
├── full_workflow/
│   ├── workflow_Giambelli.sh      # Script configured for investigator Giambelli
│   └── workflow_LaCanna.sh    # Script configured for investigator La Canna
│
└── Results/
    ├── Giambelli_A/                 # Trios 1-5 assigned to Anna Giambelli
    │   ├── trio_1/
    │   │   ├── multiqc_report.html		# Quality & Alignment metrics
    │   │   ├── trio_1.cand.vcf        # Raw candidate variants that follow the inspected inheritance pattern
    │   │   ├── trio_1.vep_filtered.vcf     # Results of the command-line annotation: variants with high impact or clinical significance
    │   │   └── [genome_browser.png]     # UCSC screenshot: visualization of Coverage & Variant tracks in the UCSC Genome Browser if subject is non-healthy
    │   └── ...
    ├── LaCanna_D/               # Trios 1-5 assigned to Davide La Canna
    │   ├── trio_1/
    │   └── ...
    └── Results_tab.tsv          # Summary of all 10 diagnoses  
```
## 💻 Bioinformatic Pipeline
Each script located in the full_workflow directory automates:

- Quality Control via FastQC (v0.11.9).

- Read Alignment via Bowtie2 (v2.3.5.1).

- Mapping Quality Control via Qualimap (v2.3).

- Summarize Final Combined Report via MultiQC (v1.14).

- Variant Calling via FreeBayes (v1.3.2).

- Mendelian Inheritance Filtering via BCFtools (v1.10.2).

## 🌐 Data Access & Environment
The analysis was conducted on the BCG2026 Shared Server (leon). Due to the size of the high-depth sequencing files and privacy considerations, raw genomic data is hosted within a restricted environment and is not included in this repository.
### Prerequisites for Reproduction:
To successfully execute each full_workflow script:

- The user must have authorized access to the 'leon' server;

- Path: the script expects a global variable COMMON_PATH set to /home/BCG2026_exam, where shared reference files (hg38 chr20) and indexes are stored.

## 🚀 Usage Instructions
To ensure the pipeline correctly identifies and processes your specific trio data, follow these configuration steps:
### 1. Configure Script Variables
Open the full_workflow shell script in a text editor and update the following variables at the top of the script:

- BASE_DATA_PATH: update with your investigator directory (i.e.: BASE_DATA_PATH="${COMMON_PATH}/BCG2026_Surname_N")

- Sample IDs: update the CHILD, FATHER and MOTHER variables with your assigned Illumina IDs (e.g., HG00406, HG00407, HG00408). This is critical for reproducibility, as the script uses these IDs to locate and link your specific FASTQ files from the server.
### 2. Data Handling
- For proper data handling, make sure that your BASE_DATA_PATH directory contains the 5 trio folders (trio_1/ through trio_5/). 

- File Naming: each trio folder must contain 6 zipped FASTQ files named consistently using the assigned Illumina IDs (e.g., ${CHILD}.targets_R1.fq.gz).

- Metadata: the mode_inherithance.tsv file must be present in your BASE_DATA_PATH, as the script parses it dynamically to apply Mendelian filters.
### 3. Execution
Once configured, provide execution permissions and launch the pipeline:
```Bash
chmod +x full_workflow.sh
./full_workflow.sh
```
#### Functional Annotation and Clinical Filtering:
After obtaining the candidate VCFs, it's possible to move inside each trio_n folder (with n = 1 ... 5) that has been created and the following commands can be used for local annotation and clinical filtering:
```Bash
# 1. Functional Annotation with VEP
vep -i trio_n.cand.vcf -o trio_n.vep_annotated.vcf --vcf --cache --offline --assembly GRCh38 \
    --dir_cache /data/vep_cache --fasta ../chr20.fa --mane --pick_allele --af --af_1kg \
    --af_gnomade --max_af --sift b

# 2. Clinical Significance Filtering
filter_vep -i trio_n.vep_annotated.vcf -o trio_n.vep_filtered.vcf \
    --filter "IMPACT is HIGH and (not MAX_AF or MAX_AF < 0.0001)"
```
#### Coverage Track Generation:
To generate the coverage data used for Genome Browser visualization tracks, the following commands are implemented inside each trio folder:
```Bash
bedtools genomecov -ibam child.bam -bg -trackline -trackopts 'name="child"' -max 100 > childCov.bg

bedtools genomecov -ibam father.bam -bg -trackline -trackopts 'name="father"' -max 100 > fatherCov.bg

bedtools genomecov -ibam mother.bam -bg -trackline -trackopts 'name="mother"' -max 100 > motherCov.bg
```
## 📊 Results Visualization
- MultiQC: To view HTML reports, please download the repository and open the files in a local web browser (GitHub does not render HTML files directly).

- Healthy Subjects: For healthy subjects, folders contain QC and VCF files to demonstrate data integrity, though Genome Browser screenshots are omitted as no pathogenic variants were identified.

- Variant Annotation Discrepancies: In certain instances (notably trio_4 assigned to investigator La Canna), the command-line VEP may omit variants found via the online interface due to differences in indel normalization or database versions between local caches and the web tool. In these cases, the genome_browser.png serves as the primary evidence to validate the existence, inheritance and coverage of the mutation.
