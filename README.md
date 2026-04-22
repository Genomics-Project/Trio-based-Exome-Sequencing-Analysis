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
├── results/
│   ├── Giambelli_A/                 # Trios 1-5 assigned to Anna Giambelli
│   │   ├── trio_1/
│   │   │   ├── multiqc_report.html		# Quality & Alignment metrics
│   │   │   ├── trio_1.cand.vcf        # Raw candidate variants that follow the inspected inheritance pattern
│   │   │   ├── trio_1.vep_filtered.vcf     # Results of the command-line annotation: variants with high impact or clinical significance
│   │   │   ├── [vep_web_results.png]    # Screenshot: Web VEP Table if subject is non-healthy
│   │   │   └── [genome_browser.png]     # Screenshot: visualization of IGV Coverage & Variant tracks if subject is non-healthy
│   │   └── ...
│   └── LaCanna_D/               # Trios 1-5 assigned to Davide La Canna
│       ├── trio_1/
│       └── ...
│
├── mode_inherithance_Giambelli.tsv # Metadata for Trios 1-5 assigned to Anna Giambelli
├── mode_inherithance_LaCanna.tsv # Metadata for Trios 1-5 assigned to Davide La Canna
└── samples.txt                  # Column order configuration
```
## 💻 Bioinformatic Pipeline
Each full_workflow.sh script located in the root directory performs:

- Quality Control via FastQC (v0.11.9).

- Read Alignment via Bowtie2 (v2.3.5.1).

- Mapping Quality Control via Qualimap (v2.3).

- Summarize Final Combined Report via MultiQC (v1.14).

- Variant Calling via FreeBayes (v1.3.2).

- Mendelian Filtering via BCFtools (v1.10.2).

## 🌐 Data Access & Environment
The analysis was conducted on the BCG2026 Shared Server (leon). Due to the size of the high-depth sequencing files and privacy considerations, the raw genomic data is hosted within a restricted environment and is not included in this repository.
### Prerequisites for Reproduction:
To successfully execute each full_workflow script:

- The user must have access to this server environment;

- Server Path: The script expects a global variable COMMON_PATH set to /home/BCG2026_exam, where shared reference files (hg38 chr20) and indexes are stored.

## 🚀 Usage Instructions
