# ASSEMBLY-mem_game
## page still in development

This project was done during course ELEC 291 at UBC (University of British Columbia) in February 2022.
The project is written completely in 8051 Assembly for the AT89LP 40 DIP u-processor.

### ** add nice photos of circuit and board

**Features:**

- [ ]  All project code and functions written in 8051 **Assembly**
- [ ]  Capacitance sensors using **555-timers A-stable oscillators**. U-processors detect touch by detecting change in period do to hand **capacitance**
- [ ]  Monotone **.WAV files** loaded onto RAM, played through the 8051 internal DAC into a onboard **LPF and Amp**

**Project Challenges:**

- Low-level assembly code writing requires great understanding of HW/SW interface. Initializing different internal clock, SPI hardware, DAC, LED screens, and configuring interrupts.
- Writing a multi-state game in low-level assembly is extremely long and complicated. Debugging tools are non-existent and the process is long

### ** add hardware and software diagrams

**Game Rules:**

- Press the **"game start"** button to start the game
- Listen to the sequence of sounds that come out of the speakers (Cow, Frog, Sheep or DJ-Khaled sounds)
- Wait for the screen to show the “Start Round” message
- **Press the sensors** in the same order as the sounds were played (Cow, Frog, Sheep or DJ-Khaled sensors)
- If you are **successful** in replicating the chain: you get to proceed to the **next level** and another sound is added to the chain.
- If you are **unsuccessful** in replicating the chain: it is **game over** for you.
- If you **pass level 15 - you win the game!**
- You can press the start game

### ** add photos of state diagram

<p align="center"><img src="https://user-images.githubusercontent.com/89616796/178293026-b8374259-d6e5-465e-b795-ed96af0089ba.jpg" title="Circuitry" width="75%" height="75%"></p>
<p align="center"><img src="https://user-images.githubusercontent.com/89616796/178294725-0feee9bd-eb5b-40d2-a6ef-765767d76673.jpg" title="game view" width="75%" height="75%"></p>
