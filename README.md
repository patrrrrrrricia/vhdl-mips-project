# MIPS Architecture: Single-Cycle & Pipeline

## 💻 Overview
A modular implementation of the **32-bit MIPS architecture**, exploring two fundamental paradigms: **Single-Cycle** (for simplicity and RTL analysis) and **Pipeline** (for performance and efficient execution). The project demonstrates hazard management, data forwarding, and the execution of complex algorithms at the register level.

---

## 🤍 Tech Stack
* **Language:** VHDL (VHSIC Hardware Description Language)
* **Tools:** Vivado
* **Architectures:** Single-Cycle, Pipeline (5 stages: IF, ID, EX, MEM, WB)
* **Design:** Modular Architecture, DataPath & Control Unit

![VHDL](https://img.shields.io/badge/VHDL-Hardware_Design-%23FF69B4.svg?style=for-the-badge&logo=vhdl&logoColor=white) 
![MIPS](https://img.shields.io/badge/MIPS-Architecture-%23FF69B4.svg?style=for-the-badge&logo=microchip&logoColor=white)

---

## 🎀 Core Functionality
* **Data Analysis Algorithm:** Solving the problem of "Counting positive and odd values in an array of N elements".
    * **Inputs:** `N` (read from address 4), Array (starting at address 8).
    * **Output:** Result written to address 0.
* **Pipeline Hazard Management:** Implementation of **Forwarding** and **Hazard Detection** units to prevent data conflicts.
* **RTL Analysis:** Generation of logical schematics to visualize the data flow.

---

## 📂 Project Structure
* **`single-cycle`**: Basic implementation where each instruction executes in a single clock cycle.
* **`pipeline`**: Advanced 5-stage implementation, including specific control units for hazards.
* **`documentatie`**: Control signal tables, RTL diagrams, and logic documentation for the problem.

---

### Implementation Details
| Variant | Architectural Details |
| :---: | :---: |
| **Single-Cycle** | Executes instructions in a single clock cycle. |
| **Pipeline** | 5-stage implementation (IF, ID, EX, MEM, WB) with hazard/forwarding units for high performance. |

---

### Implementation Details
| Variant | Architectural Details |
| :---: | :---: |
| **Single-Cycle** | Executes instructions in a single clock cycle. |
| **Pipeline** | 5-stage implementation (IF, ID, EX, MEM, WB) with hazard/forwarding units for high performance. |

---

© 2026 MIPS Architecture Lab | Developed by [**𝐋𝐞𝐨𝐧𝐭𝐞 𝐏𝐚𝐭𝐫𝐢𝐜𝐢𝐚-𝐌𝐢𝐫𝐚𝐛𝐞𝐥𝐚**](https://patrrrrrrricia.github.io/glowing-button/)
