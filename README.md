# ⚡ fsx — High-Performance CLI Tool in Pure Assembly

> A streaming text processing tool written in x86-64 assembly — built to explore systems-level engineering, performance, and low-level control.

---

## Features

- **Highlight Engine**
  - Highlight patterns in files (`--highlight=word`)
  - Case-insensitive matching
  - Streaming processing (no full file load)

- **Stats Engine**
  - Line count
  - Word count
  - Byte count
  - Multi-file aggregation

- **Benchmark Mode**
  - Measure processing speed
  - Throughput insights

- **Multi-file Support**
  - Process multiple files in one command

- **Streaming Architecture**
  - Processes data in chunks (4096 bytes)
  - No heap allocation
  - No libc dependency

---

## Example Usage

```bash
# Highlight occurrences
fsx --highlight=error file.txt

# File statistics
fsx --stats file.txt

# Combined mode
fsx --highlight=error --stats file.txt

# Multiple files
fsx --stats file1.txt file2.txt

# Benchmark mode
fsx --bench large_file.txt
```
---

## Installation

```
git clone https://github.com/raoamogh/asm-cat-plus-plus.git
cd asm-cat-plus-plus
chmod +x install.sh
./install.sh
```

---

## Uninstall

```
cd asm-cat-plus-plus
chmod +x uninstall.sh
./uninstall.sh
```

---

## How it works

fsx is built as a **stream processing pipeline**:
```
read() -> buffer -> scan -> match -> transform -> write()
```

---

## Engineering Highlights
- Written in pure x86_64 assembly
- Uses linux syscalls directly
- Implements:
    - Pattern matching engine
    - Stateful word parsing
    - Streaming architecture
- carefully avoids:
    - Register aliasing bugs
    - Syscall clobbering issues
    - Memory corruption

---

## Performance Philosophy
fsx is designed with:
- Minimal overhead
- Predictable execution
- Cache-friendly processing
- Zero dynamic allocation

---

## Benchmark 
```
Bench - Total Size: 100338 bytes
Bench - Process Time: 108 ms
Bench - Throughput: 907 KB/s
```

---

## Project Structure
```
fsx/
├── fsx.asm        # core implementation
├── install.sh     # install script
├── uninstall.sh   # uninstall script
├── README.md
```

---

## Future Work

- [] mmap-based file reading
- [] stdin support(pipe integration)
- [] regex-lite engine
- [] parallel processing
- [] SIMD Optimizations

---

## License

MIT License
