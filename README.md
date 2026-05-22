# MIPS Architecture: Single-Cycle & Pipeline

## 💻 Overview
O implementare modulară a arhitecturii **MIPS pe 32 de biți**, explorând două paradigme fundamentale: **Single-Cycle** (pentru simplitate și analiză RTL) și **Pipeline** (pentru performanță și execuție eficientă). Proiectul demonstrează gestionarea hazardurilor, forward-ul datelor și execuția de algoritmi complecși la nivel de registru.

---

## 🤍 Tech Stack
* **Limbaj:** VHDL (VHSIC Hardware Description Language)
* **Unelte:** ModelSim / Vivado / Quartus
* **Arhitecturi:** Single-Cycle, Pipeline (5 etape: IF, ID, EX, MEM, WB)
* **Design:** Arhitectură modulară, DataPath & Control Unit

![VHDL](https://img.shields.io/badge/VHDL-Hardware_Design-%23005A9C.svg?style=for-the-badge&logo=vhdl&logoColor=white) 
![MIPS](https://img.shields.io/badge/MIPS-Architecture-%23D42027.svg?style=for-the-badge&logo=microchip&logoColor=white)

---

## 🎀 Core Functionality
* **Algoritm de analiză a datelor:** Rezolvarea problemei "Numărarea valorilor pozitive și impare dintr-un șir de N elemente".
    * **Intrări:** `N` (citit de la adresa 4), Șir (începând cu adresa 8).
    * **Ieșire:** Rezultat scris la adresa 0.
* **Pipeline Hazard Management:** Implementarea unităților de **Forwarding** și **Hazard Detection** pentru a evita conflictele de date.
* **Analiză RTL:** Generarea schemelor logice pentru vizualizarea fluxului de date.

---

## 📂 Project Structure
* **`single-cycle`**: Implementarea de bază unde fiecare instrucțiune se execută într-un singur ciclu de ceas.
* **`pipeline`**: Implementarea avansată cu 5 etape, incluzând unitățile de control specifice pentru hazarduri.
* **`documentatie`**: Tabele de semnale de control, diagrame RTL și documentația logică a problemei.
---

### Structura Implementării
| Varianta | Detalii Arhitecturale |
| :---: | :---: |
| **Single-Cycle** | Execută instrucțiunile într-un singur ciclu de ceas. |
| **Pipeline** | Implementare cu 5 etape (IF, ID, EX, MEM, WB) și unități de hazard/forwarding pentru performanță ridicată. |

---

© 2026 MIPS Architecture Lab | Developed by [**𝐋𝐞𝐨𝐧𝐭𝐞 𝐏𝐚𝐭𝐫𝐢𝐜𝐢𝐚-𝐌𝐢𝐫𝐚𝐛𝐞𝐥𝐚**](https://patrrrrrrricia.github.io/glowing-button/)
