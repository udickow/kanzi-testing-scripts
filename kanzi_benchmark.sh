#!/bin/bash
# Copyright 2024-2025 Ulrik Dickow <u.dickow@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Purpose: Comprehensive compression benchmarking with timing and ratio analysis
# Enhanced version with improved readability, timing, and compression metrics

set -euo pipefail

# === CONFIGURATION ===
readonly SCRIPT_NAME="$(basename "$0")"
readonly NJOBS=${NJOBS:-$(($(nproc) / 2))}

# === UTILITY FUNCTIONS ===

usage() {
    echo "Usage: $SCRIPT_NAME FILE" >&2
    echo "Benchmark compression algorithms with timing and ratio analysis" >&2
    exit 1
}

log_info() {
    echo "[INFO] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

# Get file size in bytes
get_file_size() {
    local file="$1"
    stat -c%s "$file" 2>/dev/null || wc -c < "$file"
}

# Format size in human readable format
format_size() {
    local size="$1"
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec --suffix=B "$size"
    else
        echo "${size}B"
    fi
}

# Format time in human readable format
format_time() {
    local seconds="$1"
    if (( $(echo "$seconds < 1" | bc -l) )); then
        printf "%.3fs" "$seconds"
    elif (( $(echo "$seconds < 60" | bc -l) )); then
        printf "%.2fs" "$seconds"
    else
        printf "%dm%.0fs" $((${seconds%.*}/60)) $((${seconds%.*}%60))
    fi
}

# Calculate compression ratio as percentage
calc_ratio() {
    local original="$1"
    local compressed="$2"
    echo "scale=2; $compressed * 100 / $original" | bc -l
}

# Calculate compression speed in MB/s
calc_speed() {
    local size_bytes="$1"
    local time_seconds="$2"
    if (( $(echo "$time_seconds > 0" | bc -l) )); then
        echo "scale=2; $size_bytes / 1048576 / $time_seconds" | bc -l
    else
        echo "inf"
    fi
}

# Enhanced benchmark function with timing and metrics
benchmark_compressor() {
    local name="$1"
    local command="$2"
    local input_file="$3"
    local original_size="$4"
    
    local start_time compressed_size end_time duration ratio speed
    
    start_time=$(date +%s.%N)
    compressed_size=$(eval "$command" | wc -c)
    end_time=$(date +%s.%N)
    
    duration=$(echo "$end_time - $start_time" | bc -l)
    ratio=$(calc_ratio "$original_size" "$compressed_size")
    speed=$(calc_speed "$original_size" "$duration")
    
    # Store result for final analysis
    printf "%s|%s|%s|%s|%s\n" "$compressed_size" "$duration" "$ratio" "$speed" "$name" >> "$RESULTS_FILE"
    
    printf "%12s %10s %8.2f%% %10.2f %s\n" \
        "$(format_size "$compressed_size")" \
        "$(format_time "$duration")" \
        "$ratio" \
        "$speed" \
        "$name"
}

# === MAIN SCRIPT ===

main() {
    # Validate input
    if [[ $# -ne 1 || ! -r "$1" ]]; then
        usage
    fi
    
    local input_file="$1"
    local original_size
    
    # Check required commands
    for cmd in bc stat; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Required command '$cmd' not found"
            exit 1
        fi
    done
    
    original_size=$(get_file_size "$input_file")
    export ifile="$input_file"  # For GNU parallel
    
    # Create temporary file for results
    readonly RESULTS_FILE=$(mktemp)
    trap 'rm -f "$RESULTS_FILE"' EXIT
    
    log_info "Benchmarking compression algorithms"
    log_info "Input file: $input_file ($(format_size "$original_size"))"
    log_info "Parallel jobs: $NJOBS"
    echo
    
    # Header
    printf "%12s %10s %9s %10s %s\n" \
        "COMPRESSED" "TIME" "RATIO" "SPEED" "ALGORITHM"
    printf "%12s %10s %9s %10s %s\n" \
        "------------" "----------" "---------" "----------" "----------"
    
    # === BZIP3 BENCHMARKS ===
    printf "\n%s\n" "# BZIP3 Variants"
    
    benchmark_compressor "bzip3" \
        "bzip3 -c -j$NJOBS '$input_file'" \
        "$input_file" "$original_size"
    
    for block_size in 32 64 128 256; do
        benchmark_compressor "bzip3 -b$block_size" \
            "bzip3 -c -b$block_size -j$NJOBS '$input_file'" \
            "$input_file" "$original_size"
    done
    
    printf "\n%s\n" "# KANZI Level Presets (Default Block Size)"
    
    # === KANZI LEVEL PRESETS ===
    for level in {1..9}; do
        benchmark_compressor "kanzi -l$level" \
            "kanzi -c -x64 -l $level -j $NJOBS -i '$input_file' -o stdout" \
            "$input_file" "$original_size"
    done
    
    printf "\n%s\n" "# KANZI Level Presets (64MB Block Size)"
    
    for level in {1..9}; do
        benchmark_compressor "kanzi -b64m -l$level" \
            "kanzi -c -x64 -b 64m -l $level -j $NJOBS -i '$input_file' -o stdout" \
            "$input_file" "$original_size"
    done
    
    printf "\n%s\n" "# KANZI Large Block Sizes (Level 9)"
    
    # === KANZI LARGE BLOCK SIZES ===
    for block_size in 1m 4m 8m 16m 32m 64m 96m 128m 256m; do
        benchmark_compressor "kanzi -b$block_size -l9" \
            "kanzi -c -x64 -b $block_size -l 9 -j $NJOBS -i '$input_file' -o stdout" \
            "$input_file" "$original_size"
    done
    
    printf "\n%s\n" "# KANZI Specialized Transform Chains (64MB blocks)"
    
    # === KANZI SPECIALIZED TRANSFORMS ===
    local specialized_transforms=(
        "RLT"
        "PACK"
        "PACK+ZRLT+PACK"
        "PACK+RLT"
        "RLT+PACK"
        "RLT+TEXT+PACK"
        "RLT+PACK+LZP"
        "RLT+PACK+LZP+RLT"
        "TEXT+ZRLT+PACK"
        "RLT+LZP+PACK+RLT"
        "TEXT+ZRLT+PACK+LZP"
        "TEXT+RLT+PACK"
        "TEXT+RLT+LZP"
        "TEXT+RLT+PACK+LZP"
        "TEXT+RLT+LZP+RLT"
        "TEXT+RLT+PACK+LZP+RLT"
        "TEXT+RLT+LZP+PACK"
        "TEXT+RLT+PACK+RLT+LZP"
        "TEXT+RLT+LZP+PACK+RLT"
        "TEXT+PACK+RLT"
        "EXE+TEXT+RLT+UTF+PACK"
        "EXE+TEXT+RLT+UTF+DNA"
        "EXE+TEXT+RLT"
        "EXE+TEXT"
        "TEXT+BWTS+SRT+ZRLT"
        "BWTS+SRT+ZRLT"
        "TEXT+BWTS+MTFT+RLT"
        "BWTS+MTFT+RLT"
        "TEXT+BWT+MTFT+RLT"
        "BWT+MTFT+RLT"
    )
    
    for trans in "${specialized_transforms[@]}"; do
        benchmark_compressor "kanzi -t$trans -eTpaqx" \
            "kanzi -c -x64 -b 64m -t '$trans' -e TPAQX -j $NJOBS -i '$input_file' -o stdout" \
            "$input_file" "$original_size"
    done
    
    printf "\n%s\n" "# KANZI Parallel Tests - 4-Transform BWT/BWTS Combinations"
    
    # === PARALLEL KANZI TESTS ===
    run_parallel_kanzi_tests() {
        local test_type="$1"
        shift
        local test_commands=("$@")
        
        log_info "Running $test_type (${#test_commands[@]} tests in parallel)"
        
        printf '%s\n' "${test_commands[@]}" | \
        parallel -j"$NJOBS" --line-buffer \
            'start_time=$(date +%s.%N); 
             compressed_size=$(kanzi -c -j 1 {} -i "$ifile" -o stdout | wc -c);
             end_time=$(date +%s.%N);
             duration=$(echo "$end_time - $start_time" | bc -l);
             printf "%s|%s|%s\n" "$compressed_size" "$duration" "{}"' | \
        while IFS='|' read -r size time args; do
            ratio=$(calc_ratio "$original_size" "$size")
            speed=$(calc_speed "$original_size" "$time")
            
            # Store result for final analysis
            printf "%s|%s|%s|%s|kanzi %s\n" "$size" "$time" "$ratio" "$speed" "$args" >> "$RESULTS_FILE"
            
            printf "%12s %10s %8.2f%% %10.2f kanzi %s\n" \
                "$(format_size "$size")" \
                "$(format_time "$time")" \
                "$ratio" \
                "$speed" \
                "$args"
        done | sort -k3 -n  # Sort by ratio (column 3)
    }
    
    # 4-transform combinations with TEXT prefix
    local four_transform_tests=()
    for t2 in BWT BWTS; do
        for t3 in MTFT SRT; do
            for t4 in RLT ZRLT; do
                for e in CM TPAQ TPAQX; do
                    four_transform_tests+=("-x64 -b 64m -t TEXT+$t2+$t3+$t4 -e $e")
                done
            done
        done
    done
    
    run_parallel_kanzi_tests "4-transform TEXT combinations" "${four_transform_tests[@]}"
    
    printf "\n%s\n" "# KANZI Parallel Tests - Single Transform + Entropy"
    
    # Single transform tests
    local trans_list="NONE PACK BWT BWTS LZ LZX LZP ROLZ ROLZX RLT ZRLT MTFT RANK SRT TEXT EXE MM UTF DNA"
    local entropy_list="NONE HUFFMAN ANS0 ANS1 RANGE CM FPAQ TPAQ TPAQX"
    local single_transform_tests=()
    
    for t1 in $trans_list; do
        for e in $entropy_list; do
            single_transform_tests+=("-x64 -b 64m -t $t1 -e $e")
        done
    done
    
    run_parallel_kanzi_tests "Single transform combinations" "${single_transform_tests[@]}"
    
    printf "\n%s\n" "# KANZI Parallel Tests - Two Transform Combinations"
    
    # Two transform tests (optimized list)
    local opt_trans_list="TEXT RLT PACK ZRLT BWTS BWT LZP MTFT SRT LZ LZX ROLZ ROLZX RANK EXE MM"
    local two_transform_tests=()
    
    for t1 in $opt_trans_list; do
        for t2 in $opt_trans_list; do
            if [[ "$t1" != "$t2" ]]; then
                for e in $entropy_list; do
                    two_transform_tests+=("-x64 -b 64m -t $t1+$t2 -e $e")
                done
            fi
        done
    done
    
    run_parallel_kanzi_tests "Two transform combinations" "${two_transform_tests[@]}"
    
    printf "\n%s\n" "# KANZI Parallel Tests - Three Transform Combinations"
    
    # Three transform tests
    local three_transform_tests=()
    
    for t1 in $opt_trans_list; do
        for t2 in $opt_trans_list; do
            if [[ "$t1" != "$t2" ]]; then
                for t3 in $opt_trans_list; do
                    if [[ "$t2" != "$t3" ]]; then
                        for e in $entropy_list; do
                            three_transform_tests+=("-x64 -b 64m -t $t1+$t2+$t3 -e $e")
                        done
                    fi
                done
            fi
        done
    done
    
    run_parallel_kanzi_tests "Three transform combinations" "${three_transform_tests[@]}"
    
    # === FINAL ANALYSIS ===
    analyze_results "$original_size"
}

# Analyze results and provide recommendations
analyze_results() {
    local original_size="$1"
    
    printf "\n%s\n" "=========================================="
    printf "%s\n" "FINAL ANALYSIS & RECOMMENDATIONS"
    printf "%s\n\n" "=========================================="
    
    if [[ ! -s "$RESULTS_FILE" ]]; then
        log_error "No results found for analysis"
        return 1
    fi
    
    # Find best compression (lowest ratio)
    local best_compression
    best_compression=$(sort -t'|' -k3 -n "$RESULTS_FILE" | head -1)
    
    # Find most reasonable compression (balance of ratio and speed)
    # We'll use a weighted score: ratio * 2 + (100/speed) to favor compression but consider speed
    local best_balanced
    best_balanced=$(awk -F'|' -v orig="$original_size" '
        {
            ratio = $3
            speed = $4
            # Calculate balance score: lower is better
            # Heavily weight compression ratio, but penalize very slow speeds
            if (speed > 0) {
                balance_score = ratio * 2 + (100 / speed)
            } else {
                balance_score = ratio * 2 + 1000  # Penalty for very slow
            }
            print balance_score "|" $0
        }
    ' "$RESULTS_FILE" | sort -t'|' -k1 -n | head -1 | cut -d'|' -f2-)
    
    # Parse results
    IFS='|' read -r best_size best_time best_ratio best_speed best_name <<< "$best_compression"
    IFS='|' read -r bal_size bal_time bal_ratio bal_speed bal_name <<< "$best_balanced"
    
    printf "📊 **BEST COMPRESSION RATIO:**\n"
    printf "   Algorithm: %s\n" "$best_name"
    printf "   Size:      %s → %s (%.2f%%)\n" \
        "$(format_size "$original_size")" \
        "$(format_size "$best_size")" \
        "$best_ratio"
    printf "   Time:      %s\n" "$(format_time "$best_time")"
    printf "   Speed:     %.2f MB/s\n" "$best_speed"
    printf "   Savings:   %s (%.2f%% reduction)\n\n" \
        "$(format_size $((original_size - best_size)))" \
        "$(echo "100 - $best_ratio" | bc -l)"
    
    printf "⚖️  **MOST REASONABLE TRADE-OFF:**\n"
    printf "   Algorithm: %s\n" "$bal_name"
    printf "   Size:      %s → %s (%.2f%%)\n" \
        "$(format_size "$original_size")" \
        "$(format_size "$bal_size")" \
        "$bal_ratio"
    printf "   Time:      %s\n" "$(format_time "$bal_time")"
    printf "   Speed:     %.2f MB/s\n" "$bal_speed"
    printf "   Savings:   %s (%.2f%% reduction)\n\n" \
        "$(format_size $((original_size - bal_size)))" \
        "$(echo "100 - $bal_ratio" | bc -l)"
    
    # Additional insights
    printf "💡 **INSIGHTS:**\n"
    local total_tests=$(wc -l < "$RESULTS_FILE")
    local fast_tests=$(awk -F'|' '$4 > 100' "$RESULTS_FILE" | wc -l)
    local good_compression=$(awk -F'|' '$3 < 5' "$RESULTS_FILE" | wc -l)
    
    printf "   • Tested %d compression configurations\n" "$total_tests"
    printf "   • %d algorithms achieved >100 MB/s speed\n" "$fast_tests"
    printf "   • %d algorithms achieved <5%% compression ratio\n" "$good_compression"
    
    if (( $(echo "$best_ratio < 3" | bc -l) )); then
        printf "   • Excellent compression achieved (<%%.0f%%)\n" 3
    elif (( $(echo "$best_ratio < 5" | bc -l) )); then
        printf "   • Very good compression achieved (<%%.0f%%)\n" 5
    fi
    
    if (( $(echo "$bal_speed > 50" | bc -l) )); then
        printf "   • Balanced option provides good speed (>50 MB/s)\n"
    fi
}

# Run main function
main "$@"
