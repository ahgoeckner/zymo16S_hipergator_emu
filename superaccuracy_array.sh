#!/bin/bash

#SBATCH --job-name=dorado_basecall
#SBATCH --account=duttonc
#SBATCH --qos=duttonc
#SBATCH --partition=hpg-turin
#SBATCH --gpus=2
#SBATCH --cpus-per-task=24
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=agoeckner@ufl.edu
#SBATCH --array=0-73
#SBATCH -o /blue/duttonc/agoeckner/DOE_16S/99_logs/superaccuracy_%A_%a.out
#SBATCH -e /blue/duttonc/agoeckner/DOE_16S/99_logs/superaccuracy_%A_%a.err

cd /blue/duttonc/agoeckner/DOE_16S/01_pod5/20251118_Goeckner_DOE_April2025-July2025_pod5

# Ensure output directory exists
OUTPUT_DIR="/blue/duttonc/agoeckner/DOE_16S/02_superaccuracy/20251118_Goeckner_DOE_April2025-July2025_super"
mkdir -p "$OUTPUT_DIR" #-p checks to see if directory exists, skips if it does 

# Gather .pod5 files in /blue/duttonc/agoeckner/DOE_16S/01_pod5
pod5_files=( *.pod5 )

POD5_FILE="${pod5_files[$SLURM_ARRAY_TASK_ID]}"
OUT_NAME="$OUTPUT_DIR/$(basename "$POD5_FILE" .pod5)_sup.fastq"

module load cuda/12.9.1
module load dorado

dorado basecaller --device cuda:all /blue/duttonc/shared_resources/dorado/dorado_basecalling_models/dna_r10.4.1_e8.2_400bps_sup@v5.0.0 "$POD5_FILE" --no-trim --emit-fastq > "$OUT_NAME"
