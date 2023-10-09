
---
title: RustPM - Safe and Efficient Persistent Memory Systems in Rust
aliases:
- /rustpm

ShowReadingTime: false
--- 


Persistent memory (PM) hardware such as Intel’s Optane DC memory product
promises to transform how programs store and manipulate information. Persistent
memory provides a mixture of the performance and flexibility of DRAM and the
price and persistence of FLASH storage. There has been much exciting work in
the systems community to explore how persistent memory enables new more
efficient designs of storage systems ranging from file systems that bypass the
kernel to key-value storage systems to concurrent DRAM indices to databases.

Unfortunately, developing correct persistent memory code is extremely
challenging. Stores to persistent memory do not immediately update the
underlying PM. Instead, stores to PM are first written to the processor cache
and are only later written to the underlying PM when the cache line is evicted
or explicitly flushed.  Thus, machine crashes can leave applications in an
inconsistent state. The difficulty of using PM is well known and researchers
have developed many bug finding tools to find missing flush instructions.

Persistency bugs do not just affect the correctness of application code, they
can easily subvert the safety guarantees of safe programming languages like
Rust — for example, a persistency bug could leave a reference in a persistent
data structure to a previously freed object or create multiple aliases that all
own the same object. The proposed work will develop a lightweight verification
approach to ensure the safety of efficient persistent memory code.  

Our work aims to build the RustPM verification system for persistent memory
systems that guarantees crash consistency. Our basic approach has two
components: (1) verify that a program correctly uses flush and fence operations
and (2) verify that the data structure operations are failure atomic. We
propose to implement the verification system for the Rust programming language.


# NSF Award

[FMitF: Track I: Safe, Efficient Persistent Memory Systems](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2220410)



