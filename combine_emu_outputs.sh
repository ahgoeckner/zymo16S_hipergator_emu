#!/bin/bash

#SBATCH --job-name=emu_combine_1_test
#SBATCH --account=duttonc
#SBATCH --qos=duttonc
#SBATCH --partition=hpg-turin
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=2:00:00
#SBATCH --output=/blue/duttonc/agoeckner/DOE_16S/99_logs/emu_combine_1_test.log
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=agoeckner@ufl.edu

# Directory of emu output (each sample has their own folder)
cd /blue/duttonc/agoeckner/DOE_16S/03_emu_tax/20251118_Goeckner_DOE_April2025-July2025_genus

echo "Creating combined counts table with proper row matching..."

# Step 1: Get all unique tax_ids and their taxonomy info across ALL samples
echo "Getting all unique taxa..."
# Add header
echo -e "tax_id\tspecies\tgenus\tfamily\torder\tclass\tphylum\tclade\tsuperkingdom\tsubspecies\tspecies_subgroup\tspecies_group" > all_unique_taxa.tsv
cat S*/S*_merged_for_emu.fastq_rel-abundance.tsv | \
awk -F $'\t' 'NR>1 {print $1"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10"\t"$11"\t"$12"\t"$13}' | \
sort -u >> all_unique_taxa.tsv

# Step 2: Create header for count file WITH tax_id column
# Find which samples exist
SAMPLES=()
echo -e "tax_id" > combined_emu_counts.tsv
for i in {193..288}; do
    if [[ -f "S${i}/S${i}_merged_for_emu.fastq_rel-abundance.tsv" ]]; then
        SAMPLES+=("S${i}")
        printf "\tS${i}" >> combined_emu_counts.tsv
    fi
done
printf "\n" >> combined_emu_counts.tsv

echo "Found ${#SAMPLES[@]} samples: ${SAMPLES[*]}"

# Step 3: For each unique tax_id, get counts from each sample
echo "Matching taxa across all samples..."

while IFS=$'\t' read -r tax_id species genus family order class phylum clade superkingdom subspecies species_subgroup species_group; do
    # Start row with tax_id
    printf "%s" "$tax_id" >> combined_emu_counts.tsv
    
    # For each sample, look up this tax_id and get its count
    for sample in "${SAMPLES[@]}"; do
        counts=$(awk -F $'\t' -v tid="$tax_id" '$1==tid {print $14; exit}' "${sample}/${sample}_merged_for_emu.fastq_rel-abundance.tsv")
        if [[ -z "$counts" ]]; then
            counts="0"
        fi
        printf "\t%s" "$counts" >> combined_emu_counts.tsv
    done
    printf "\n" >> combined_emu_counts.tsv
done < <(tail -n +2 all_unique_taxa.tsv)

# Step 4: Paste emu counts next to formatted taxonomy table
paste all_unique_taxa.tsv <(cut -f2- combined_emu_counts.tsv) > combined_emu_counts_with_taxonomy_genus.tsv

# Step 5: Create CSV version (from final table with taxonomy)
sed 's/\t/,/g' combined_emu_counts_with_taxonomy_genus.tsv > combined_emu_counts_with_taxonomy_genus.csv

# Clean up
rm all_unique_taxa.tsv
rm combined_emu_counts.tsv

echo "Done! Created:"
echo "- combined_emu_counts_with_taxonomy_genus.tsv"
echo "- combined_emu_counts_with_taxonomy_genus.csv" 
echo "Total unique taxa: $(tail -n +2 combined_emu_counts_with_taxonomy_genus.tsv | wc -l)"
echo "Samples included: ${#SAMPLES[@]}"

# Verify the data looks correct
echo ""
echo "First few rows of the combined data:"
head -3 combined_emu_counts_with_taxonomy_genus.tsv
