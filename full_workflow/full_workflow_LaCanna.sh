echo "Workspace setup: starting..."

# First of all, define the consistent IDs for my assigned trio (static for all 5 trios).
CHILD="HG00406"
FATHER="HG00407"
MOTHER="HG00408"

# Then, define paths for shared resources and personal data
COMMON_PATH="/home/BCG2026_exam"
BASE_DATA_PATH="${COMMON_PATH}/BCG2026_LaCanna_D"
BED_FILE="../chr20_ILMN_Exome_2.0_Plus_Panel.hg38_padded.bed"

echo "Linking common reference and target files..."

# Link the chr20 reference sequence and Bowtie2 index files (prefix chr20*), as well as the exome target regions BED file
ln -s ${COMMON_PATH}/chr20* .

# Link mode_inheritance.tsv
ln -s ${BASE_DATA_PATH}/mode_inherithance.tsv .

# Create samples.txt for consistent column ordering
echo -e "child\nfather\nmother" > samples.txt

# Loop from 1 to 5 to iterate the following operations over each trio
for n in {1..5}
do
	# Define the directory name (e.g., trio_1)
	DIR_NAME="trio_${n}"
	echo "Setting up workspace for $DIR_NAME..."
	# Create the directory
	mkdir -p "$DIR_NAME"
	# Link all files from the server's trio folder to my local trio folder
	# This will include the 6 paired-end files (_R1 and _R2 for 3 people)
	# Link for child
	ln -s "${BASE_DATA_PATH}/trio_${n}/${CHILD}.targets_R1.fq.gz" "${DIR_NAME}/child_R1.fq.gz"
	ln -s "${BASE_DATA_PATH}/trio_${n}/${CHILD}.targets_R2.fq.gz" "${DIR_NAME}/child_R2.fq.gz"
	# Link for FATHER
	ln -s "${BASE_DATA_PATH}/trio_${n}/${FATHER}.targets_R1.fq.gz" "${DIR_NAME}/father_R1.fq.gz"
	ln -s "${BASE_DATA_PATH}/trio_${n}/${FATHER}.targets_R2.fq.gz" "${DIR_NAME}/father_R2.fq.gz"
	# Link for MOTHER
	ln -s "${BASE_DATA_PATH}/trio_${n}/${MOTHER}.targets_R1.fq.gz" "${DIR_NAME}/mother_R1.fq.gz"
	ln -s "${BASE_DATA_PATH}/trio_${n}/${MOTHER}.targets_R2.fq.gz" "${DIR_NAME}/mother_R2.fq.gz"

	echo "Workspace setup complete for $DIR_NAME"

	echo "Starting analysis for $DIR_NAME ..."
	# Now move inside the folder trio_n
	cd ${DIR_NAME}

	# Step 1: Quality Control (FastQC); process both R1 and R2 for each sample
	echo "Starting quality control of raw reads in $DIR_NAME ..."
	fastqc *.fq.gz

	# Step 2: Paired-End Alignment (Bowtie2) and qualimap
	# We use -1 and -2 for paired reads and pipe to samtools for sorting
	# Step 2A: Align child
	echo "Aligning child reads from $DIR_NAME  ..."
	bowtie2 -x ../chr20 -1 "child_R1.fq.gz" -2 "child_R2.fq.gz" --rg-id "child" --rg "SM:child" -p 8 | samtools view -Sb | samtools sort -o child.bam
	# Step 2B: Align father
	echo "Aligning father reads from $DIR_NAME  ..."
	bowtie2 -x ../chr20 -1 "father_R1.fq.gz" -2 "father_R2.fq.gz" --rg-id "father" --rg "SM:father" -p 8 | samtools view -Sb | samtools sort -o father.bam
	# Step 2C: Align mother
	echo "Aligning mother reads from $DIR_NAME  ..."
	bowtie2 -x ../chr20 -1 "mother_R1.fq.gz" -2 "mother_R2.fq.gz" --rg-id "mother" --rg "SM:mother" -p 8 | samtools view -Sb | samtools sort -o mother.bam

	# Step 2D: Indexing and Qualimap (using the new generic names)
	for role in child father mother; do
		samtools index "${role}.bam"
		qualimap bamqc -bam "${role}.bam" -gff "$BED_FILE" --outdir "${role}"
	done

	# Final combined report (multiqc)
	multiqc . -o "multiqc_trio_${n}"

	# Step 3: Multi-sample Variant Calling (Freebayes)
	# Generic names (child, father, mother) make the final VCF columns much easier to read
	echo "Calling variants for $DIR_NAME ..."
	freebayes -f ../chr20.fa -m 20 -C 5 -Q 10 -q 10 --min-coverage 10 child.bam father.bam mother.bam > "trio_${n}.vcf"
	# Compressing the vcf file
	bgzip trio_${n}.vcf
	# Indexing the compressed vcf file
	bcftools index trio_${n}.vcf.gz

	# Step 4: Filtering
	echo "Retrieving model of inheritance for $DIR_NAME ..."
	# Step 4A: Standardize Trio ID for the search, handling the inconsistency in our TSV file
	TRIO_ID="trio_${n}"
	if [ $n -eq 1 ]; then TRIO_ID="trio1"; fi
	# Step 4B: Extract the full line for that trio
	# -w ensures we match the whole word only
	TRIO_LINE=$(grep -w "$TRIO_ID" ../mode_inherithance.tsv)
	# Step 4C: Use 'cut' to extract columns (tab-separated)
	# Column 3 is 'mode', Column 4 is 'notes'
	MODE=$(echo "$TRIO_LINE" | cut -f 3)
	NOTES=$(echo "$TRIO_LINE" | cut -f 4)

	# Step 4D: Conditional Logic for the 4 patterns
	echo "Processing $TRIO_ID: Mode=$MODE, Notes=$NOTES"
	if [ "$MODE" == "AR" ]; then
		# Autosomal Recessive: Child is AA, both parents are carriers (RA)
		FILTER='GT[0]=="AA" && GT[1]=="RA" && GT[2]=="RA"'
	elif [ "$MODE" == "AD_denovo" ]; then
		# AD De Novo: Child is RA, both parents are healthy (RR)
		FILTER='GT[0]=="RA" && GT[1]=="RR" && GT[2]=="RR"'
	elif [ "$MODE" == "AD_inherited" ]; then
		if [ "$NOTES" == "mother_affected" ]; then
			# Mother affected: Child RA, Father RR, Mother RA
			FILTER='GT[0]=="RA" && GT[1]=="RR" && GT[2]=="RA"'
		elif [ "$NOTES" == "father_affected" ]; then
			# Father affected: Child RA, Father RA, Mother RR
			FILTER='GT[0]=="RA" && GT[1]=="RA" && GT[2]=="RR"'
		fi
	fi

	# Step 4E: use the retrieved info to filter the vcf file and obtain a file with the candidate variants
	echo "Filtering variants according to model of inheritance ..."
	bcftools view -R ../chr20_ILMN_Exome_2.0_Plus_Panel.hg38_padded.bed trio_${n}.vcf.gz | bcftools view -S ../samples.txt | bcftools view -i "$FILTER" | bcftools filter -i 'QUAL>20' -Ov -o trio_${n}.cand.vcf
	echo "Analysis complete for $DIR_NAME."
	cd .. # Return to main project folder before next loop
done

