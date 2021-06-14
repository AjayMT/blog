---
layout: post
title:  "Linking ELF files"
date:   2021-06-13 21:10:48 -0500
categories: compilers
---

(For the purposes of this article, "executable" means "statically linked executable".)

I spent the last few months writing [nanoc](https://github.com/AjayMT/nanoc), a small compiler for a C-like language. nanoc produces ELF executables for 32-bit x86 computers without depending on an assembler or linker. In this post, I will attempt to explain how nanoc links multiple object files together to produce an executable, and a little bit about how more complex "real" linkers work.

## The ELF format
On most operating systems, running programs use four distinct regions of memory:
- executable code ("text")
- statically allocated objects ("data")
- dynamically allocated memory ("heap")
- stack

The ELF format maps parts of an executable file more or less directly to the text and data regions of memory. ELF executables consist of multiple segments, two of which are the `.text` and `.data` segments that are copied into memory when the executable is loaded.

The ELF format also encodes object files. ELF object files differ from ELF executables in two important ways:
- they are not self-contained; they depend on code and data in other object files
- they contain **relocation entries**

This means that object files cannot be loaded directly into memory and executed -- they are meant to be linked with other object files first.

One minor difference in terminology: executable files contain *segments*, object files contain *sections*. In practice, these terms are usually interchangeable.

ELF files consist of headers, which describe the structure of the file and the locations and sizes of the sections in the file, and the sections themselves, which contain code, data, names of symbols and other information. The [ELF man page](https://man.openbsd.org/elf.5) provides a comprehensive description of ELF headers -- it suffices to know that ELF headers specify the names, locations and sizes of sections.

Generally, ELF object files consist of the following sections:
- `.text`: executable code
- `.data`: statically allocated objects (ex: global variables initialized with non-zero values)
- `.bss`: statically allocated objects that are expected to be zero-initialized when the program is loaded (ex: uninitialized global variables)
- `.rodata`: read-only statically allocated objects (ex: string literals)
- `.symtab`: the symbol table; symbols are either functions (located in the `.text` section) or global variables (located in one of the data sections)
- `.strtab`: symbol names; entries in the `.symtab` specify symbol names as offsets into the `.strtab` section
- `.rel.text`: relocation entries; addresses of symbols that the linker will have to fill in
- other sections (mostly for debugging and other information) that nanoc does not use

nanoc links object files in two steps:
1. Consolidating text and data
2. Relocation and symbol resolution

## Consolidating text and data
This step involves gathering all the discrete `.text` and various data sections of all the object files and concatenating them into a single text section and a single data section.

![](/blog/assets/linking-elf-consolidate.svg)

In doing so, the linker must also record the positions of all the symbols (functions and variables) defined in the object files.

The `.symtab` section of each object file is an array of `Elf32_Sym` entries, which are defined as follows:
```c
typedef struct {
  Elf32_Word    st_name;
  Elf32_Addr    st_value;
  Elf32_Word    st_size;
  unsigned char st_info;
  unsigned char st_other;
  Elf32_Half    st_shndx;
} Elf32_Sym;
```
(`Elf32_Half` is defined as a `uint16_t`, `Elf32_Word` and `Elf32_Addr` are `uint32_t`)

The `st_name` field is the location in the `.strtab` section at which the name of this symbol is stored. `st_shndx` and `st_value` specify the index of the section containing the symbol and the offset within that section respectively -- in other words, the location of this symbol within the object file.

nanoc performs the following operations for each object file:
1. Record the current size of the aggregated (executable) text section; I call this value the "text offset".
2. Append the object file's text section to the executable text section.
3. For each symbol in the object file, add the text offset to the symbol's `st_value`, i.e its offset in the object file's text section. This is the symbol's location in the executable text section.
4. Add the symbol and its location to the aggregated symbol table.

nanoc performs a similar process to consolidate the data sections and symbols. After this is complete, the linker must resolve symbols and perform relocations to produce a working executable.

## Relocation and symbol resolution
Many instructions -- jump, call, load, store, etc. -- refer to symbols that may be defined in the same object file or elsewhere. Most of these symbols have unknown addresses at compile time, so the compiler outputs a placeholder address and adds a "relocation entry" to the `.rel.text` section of the object file for each symbol reference.

Each relocation entry specifies:
- the offset into the `.text` section of the placeholder address, i.e the location at which to write the resolved address
- the index (in the `.symtab` section) of the symbol being referenced
- the type of the relocation (defined below)

The `.rel.text` section is an array of `Elf32_Rel` objects:
```c
typedef struct {
  Elf32_Addr r_offset; // offset in the .text section
  Elf32_Word r_info;   // symbol index and relocation type
} Elf32_Rel;
```

The following macros are used to obtain symbol and type information from the `r_info` field of each `Elf32_Rel` object:
```c
// Macros to apply to r_info
#define ELF32_R_SYM(i)    ((i)>>8)
#define ELF32_R_TYPE(i)   ((unsigned char)(i))
#define ELF32_R_INFO(s,t) (((s)<<8)+(unsigned char)(t))

// R_TYPE values
#define R_386_32   1
#define R_386_PC32 2
```

For example, given an `Elf32_Rel` object `rel`, `ELF32_R_SYM(rel.r_info)` is the index of the referenced symbol and `ELF32_R_TYPE(rel.r_info)` is the type of the relocation.

The relocation type values specified above are architecture-specific: they are only applicable to 32-bit x86, and are only two of many relocation types for x86. [Here](https://docs.oracle.com/cd/E19683-01/817-3677/chapter6-26/index.html) is a full list of relocation types for x86 and other architectures.

The relocation type values specify whether to write an absolute address (`R_386_32`) or a *PC-relative* address (`R_386_PC32`).

For each relocation of type `R_386_32`, the resolved address is:
```
symbol_offset + text_start
```
where `symbol_offset` is the offset of the symbol being referenced within the text section, and `text_start` is the address at which the text section is placed when the executable is loaded (i.e the start of the text section at runtime).

For each relocation of type `R_386_PC32`, the resolved address is:
```
symbol_offset - relocation_offset - 4
```
where `relocation_offset` is the offset of the placeholder address within the aggregated text section -- this is the "text offset" of this object file's text section plus the `r_offset` field of the `Elf32_Rel` object. The value of the program counter **after** reading the resolved address would be `relocation_offset + text_start + 4` (since the address is 4 bytes long). Therefore, the *PC-relative* address of the symbol is
```
symbol_offset + text_start - (relocation_offset + text_start + 4)
```
which is the same as `symbol_offset - relocation_offset - 4`.

For each relocation, nanoc looks up the referenced symbol in the aggregated symbol table, calculates the resolved address as specified above and writes it to the aggregated text section at the relocation offset.

After this is done, the process of linking is complete. The final step is to write the ELF headers and the contents of the consolidated text and data sections to the executable file, after which it is ready to be loaded and run.

## Conclusion
The process of linking is complex and poorly specified. Much of what is described here is a result of my own design choices and is not true of all linkers. More sophisticated linkers like GNU ld implement many more features, like multiple levels of visibility, symbol alignment and support for linker scripts. If you decide to write your own linker or want to learn more about how they work, these are excellent resources:
- Build your own linker: <https://github.com/andrewhalle/byo-linker>
- Linkers and Loaders: <https://www.amazon.com/dp/1558604960>
- Ian Lance Taylor's blog: <https://www.airs.com/blog/archives/38>
- ELF symtab and relocation reference: <https://refspecs.linuxbase.org/elf/gabi4+/ch4.symtab.html>

nanoc, the small compiler and linker that this article is based on, is here: <https://github.com/AjayMT/nanoc>.
