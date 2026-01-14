# Gopher Hunt Game (Flutter)

A bot-vs-bot Flutter game where two automated players compete to find a hidden gopher on an 8×8 grid. Once the game starts, there is no human input beyond starting, stopping, or exiting the app. Each bot makes guesses in turn, receives feedback (hit, near miss, or miss), and the first bot to guess the gopher’s exact location wins.

This project was built for CS378: Framework-Based Software Development for Hand-Held Devices, Project 4.

---

## Gameplay

- The board contains 64 holes arranged as an 8×8 grid.
- At the start of each game, the controller randomly selects a hidden gopher location (row 0–7, col 0–7).
- Two bots take turns guessing a coordinate `(row, col)`.
- After each guess, the controller returns one of:
  - Success: exact gopher location (game ends)
  - Near miss: one of the 8 adjacent cells (including diagonals)
  - Complete miss: any other cell
- The game runs in continuous play mode:
  - After every move, the app pauses for 2 seconds so the move is visible
  - Then it switches turns until a winner is found

---

## Bots

The app includes two player classes that implement different strategies:

- Random bot: selects a random unguessed cell each turn
- Heuristic bot: uses feedback to guide guesses (for example, prioritizing areas near near-misses or following a systematic search pattern)

Both players expose async methods for:
- Producing the next move
- Resetting their internal state when a new game starts

---

## UI Overview

The main screen contains:

- A control row with Start, Stop, and Exit buttons
- A status section showing:
  - Running or Stopped state
  - Current turn
  - The gopher location displayed to the user (not visible to player classes)
- Two separate 8×8 boards (one per bot) showing guess order and outcomes
- A scrollable guess log showing the full move history

Visual behavior:
- Guessed cells are color-coded by result (hit, near miss, miss)
- Each guessed cell shows the guess number
- Cell transitions are animated to make updates smooth
- The current-turn label transitions smoothly when turns switch

---

## Project Structure (typical)

```text
lib/
  main.dart
  game_controller.dart
  players/
    random_player.dart
    smart_player.dart
```

Names may vary slightly depending on your final organization.

---

## Run Locally

1. Install Flutter and confirm your environment:
   ```bash
   flutter doctor
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Run on an emulator or device:
   ```bash
   flutter run
   ```

---

## Controls

- Start: resets the game, re-randomizes the gopher location, resets both bots, and begins continuous play
- Stop: halts the current game loop
- Exit: closes the app

---

## LLM Usage

This project used an LLM as required by the course. ChatGPT was used to help refine the specification and to assist with implementation and debugging (especially UI layout and game-loop structure).

---

## Notes

- This app is designed for coursework and demonstration purposes.
- There is no backend; all game state is local to the app.