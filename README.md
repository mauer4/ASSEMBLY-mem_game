# Memory Game 
## Written in 8051 Assembly - Implemented on $u$-processor ##

## Contents

* [General](#general)
* [Features](#features)
* [Project Challenges](#project-challenges)
* [Hardware and Software Diagrams](#hardware-and-software-diagrams)
* [Game Rules](#game-rules)
* [State Diagram](#state-diagram)
* [Assembly Code Snippets](#assembly-code-snippets)

### General

This project was done during course ELEC 291 at UBC (University of British Columbia) in February 2022.
The project is written completely in 8051 Assembly for the AT89LP 40 DIP u-processor.

<p align="center"><img src="/Media/Photos/Pictures/Circuitry_B.jpg" title="game view" width="50%" height="50%"></p>
<p align="center"><img src="/Media/Photos/Pictures/Front_view_B.jpg" title="game view" width="50%" height="50%"></p>

### **Features:**

- [ ]  All project code and functions written in 8051 **Assembly**
- [ ]  Capacitance sensors using **555-timers A-stable oscillators**. U-processors detect touch by detecting change in period do to hand **capacitance**
- [ ]  Monotone **.WAV files** loaded onto RAM, played through the 8051 internal DAC into a onboard **LPF and Amp**

### **Project Challenges:**

- Low-level assembly code writing requires great understanding of HW/SW interface. Initializing different internal clock, SPI hardware, DAC, LED screens, and configuring interrupts.
- Writing a multi-state game in low-level assembly is extremely long and complicated. Debugging tools are non-existent and the process is long

### Hardware and Software Diagrams 

<p align="center"><img src="/Media/Photos/Diagrams/Hardware_sketch.png" title="game view" width="50%" height="50%"></p>
<p align="center"><img src="/Media/Photos/Diagrams/Software_sketch.png" title="game view" width="50%" height="50%"></p>

### **Game Rules:**

- Press the **"game start"** button to start the game
- Listen to the sequence of sounds that come out of the speakers (Cow, Frog, Sheep or DJ-Khaled sounds)
- Wait for the screen to show the “Start Round” message
- **Press the sensors** in the same order as the sounds were played (Cow, Frog, Sheep or DJ-Khaled sensors)
- If you are **successful** in replicating the chain: you get to proceed to the **next level** and another sound is added to the chain.
- If you are **unsuccessful** in replicating the chain: it is **game over** for you.
- If you **pass level 15 - you win the game!**
- You can press the start game

### State Diagram

<p align="center"><img src="/Media/Photos/Diagrams/State_digram.png" title="game view" width="50%" height="50%"></p>

### Assembly code Snippets

** All source code in the /source directory

<p align="center"><img src="/Media/Photos/Code/Sound_assembly.png" title="game view" width="50%" height="50%"></p>
<p align="center"><img src="/Media/Photos/Code/Play_sound_assembly.png" title="game view" width="50%" height="50%"></p>
<p align="center"><img src="/Media/Photos/Code/Play_sound2_assembly.png" title="game view" width="50%" height="50%"></p>
