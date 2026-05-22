---

## ⚙️ MIPS Processor Implementation
Implementările VHDL pentru arhitectura MIPS, structurate pe două niveluri: `single-cycle` și `pipeline`.

### Problema abordată: Analiza șirului de date
**Cerință:** Determinarea numărului de valori **pozitive și impare** dintr-un șir de **N** elemente.
* **Intrări:** * `N` se citește de la adresa de memorie `4`.
    * Șirul de date începe de la adresa `8`.
* **Ieșire:** Numărul total de valori găsite se scrie la adresa de memorie `0`.

### Structura Implementării
| Varianta | Detalii Arhitecturale |
| :---: | :---: |
| **Single-Cycle** | Execută instrucțiunile într-un singur ciclu de ceas. Ideal pentru înțelegerea fluxului de date. |
| **Pipeline** | Implementare cu 5 etape (IF, ID, EX, MEM, WB) și unități de hazard/forwarding pentru performanță ridicată. |
