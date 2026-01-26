#!/bin/bash

#SBATCH --job-name=minibar_demux_serial
#SBATCH --account=duttonc
#SBATCH --qos=duttonc
#SBATCH --partition=hpg-turin
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=54:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=agoeckner@ufl.edu
#SBATCH -o /blue/duttonc/agoeckner/DOE_16S/99_logs/demux2.o
#SBATCH -e /blue/duttonc/agoeckner/DOE_16S/99_logs/demux2.e

module load apptainer

WORKDIR="/blue/duttonc/agoeckner/DOE_16S/02_superaccuracy/20260106_Goeckner_DOE_Nov2024-Feb2025_super"
MINIBAR_SIF="/blue/duttonc/duttonc/giraffe/minibar_latest.sif"

cd "$WORKDIR"

# Download minibar and barcode resources if not already present
if [ ! -f minibar_and_barcodes.zip ]; then
    wget https://zymo-microbiomics-service.s3.amazonaws.com/epiquest/epiquest_in4521/VUCKWUBPTZJFQRXS/rawdata/240903/minibar_and_barcodes.zip
    unzip minibar_and_barcodes.zip
fi

# Build the minibar Apptainer image if not already present
if [ ! -f "$MINIBAR_SIF" ]; then
    apptainer build "$MINIBAR_SIF" docker://stang/minibar:v1
fi

# Process each fastq file one-by-one
for THIS_FASTQ in *.fastq; do
    [ -e "$THIS_FASTQ" ] || continue
    echo "Processing $THIS_FASTQ with minibar..."
    apptainer exec "$MINIBAR_SIF" python3 minibar.py barcodes.tsv "$THIS_FASTQ" -e 1 -E 5 -M 2 -T -F

    BASE_SRC=$(basename "$THIS_FASTQ" .fastq)
    for OUT_FQ in sample_*.fastq; do
        [ -e "$OUT_FQ" ] || continue
        BARCODE=$(echo "$OUT_FQ" | sed 's/sample_\(.*\)\.fastq/\1/')
        mkdir -p "$WORKDIR/$BARCODE"
        mv "$OUT_FQ" "$WORKDIR/$BARCODE/${BARCODE}__${BASE_SRC}.fastq"
    done
done

echo "All samples processed."
