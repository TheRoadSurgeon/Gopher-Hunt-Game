
# Gopher Hunt Game – Refined Specification

## 1. Overview

This project implements a **bot-vs-bot game** called **Gopher Hunt Game** as a Flutter app.

- The playing field has **64 holes** arranged in an **8×8 grid**.
- A hidden **gopher** occupies exactly one of these holes.
- Two computer-controlled players (bots) take turns guessing the gopher’s location.
- The first bot to correctly guess the gopher’s hole **wins the game**.
- Once the game starts, there is **no human input**: the bots play continuously until there is a winner.

## 2. Game Rules and Feedback

- At the **start of the game**, the main code randomly chooses one cell (row 0–7, col 0–7) to contain the gopher.  
  This location is **never visible to the player classes**; only the main controller knows it.
- On each turn:
  - The current bot proposes a guess: a pair `(row, col)` with `0 ≤ row, col < 8`.
  - The main controller compares the guess with the gopher’s position and returns one of three feedback values.

### Feedback types

1. **Success**
   - The guessed hole is exactly the gopher’s hole.
   - The guessing player **wins the game**.
   - A **SnackBar** appears at the bottom of the screen with the message:  
     `"<winner-name> found the gopher in <N> guesses!"`

2. **Near miss**
   - The guessed hole is one of the **8 neighboring holes** around the gopher (horizontal, vertical, or diagonal adjacency).
   - The board is updated to show a **“near miss” color** for this cell.
   - The game continues with the **other player’s turn**.

3. **Complete miss**
   - Any other guess that is not the gopher and not adjacent to it.
   - The board is updated to show a **“complete miss” color**.
   - The game continues with the **other player’s turn**.

- The game runs in **continuous-play mode**:
  - After each move, there is a **2 second pause** so the user can see the move.
  - Then the turn switches to the other player, until there is a Success.

## 3. Main Classes and Files

The app uses at least the following main Dart files:

### 3.1 `main.dart`

- Contains the Flutter UI (`GameScreen` widget) and wires the game together.
- Creates and holds:
  - The `GopherGameController`
  - The two player instances:
    - `RandomGopherPlayer` (Player 1)
    - `HeuristicGopherPlayer` (Player 2)
- Manages the **game loop**, including:
  - Asking the current player for a move
  - Registering feedback
  - Updating the UI
  - Enforcing the **2 second delay** between moves

### 3.2 `game_controller.dart`

Defines:

- The **game state**:
  - `gopherRow`, `gopherCol`
  - `board1`, `board2` (2D lists of `CellState` for each player)
  - `currentTurn` (enum for Player 1 / Player 2)
  - `winnerName`
  - Global `guessCounter`
  - `guessLog` (history of guesses with player, position, result)
- The **`GuessResult` enum**: `hit`, `nearMiss`, `miss`.
- The **`CellState`** model:
  - `GuessResult? result`
  - `int? guessNumber`

Responsibilities:

- Randomly picking the gopher’s location at the start of each game.
- Exposing helper methods such as:
  - `registerGuess(Point<int> move)` → returns `GuessResult`
  - `toggleTurn()`
  - `isGopherCell(row, col)`
  - `resetGame()`
  - `formatPosition(row, col)` → string like `(r, c)`
- Capturing every guess into `guessLog`.

### 3.3 `players/random_player.dart`

Implements **Player 1: `RandomGopherPlayer`**.

- Fields:
  - `String name` (e.g., `"Random Bot"`)
- Async methods (required by spec):
  - `Future<Point<int>> makeMove()`
    - Chooses a **random unguessed cell** from the 8×8 board.
    - Returns the chosen `(row, col)` as a `Point<int>`.
  - `Future<void> resetAsync()`
    - Clears internal state (if any).
    - Called when the game is (re)started; UI does **not** wait for this to finish.
- Feedback:
  - `void handleFeedback(GuessResult result, Point<int> move)`
    - Receives the result of the last guess, but does not use it heavily (pure random strategy).

### 3.4 `players/smart_player.dart`

Implements **Player 2: `HeuristicGopherPlayer`**.

- Fields:
  - `String name` (e.g., `"Heuristic Bot"`)
- Async methods:
  - `Future<Point<int>> makeMove()`
    - Uses a **sensible heuristic** to improve search:
      - May maintain a list of untried cells.
      - Prioritizes cells near previous **near misses**, or uses a more systematic pattern (for example scanning row by row or using a checkerboard pattern).
    - Returns the chosen `(row, col)` as a `Point<int>`.
  - `Future<void> resetAsync()`
    - Resets internal data structures and history.
- Feedback:
  - `void handleFeedback(GuessResult result, Point<int> move)`
    - Updates its internal model based on whether the guess was a hit, near miss, or complete miss.
    - Uses this information to guide future guesses.

## 4. UI Layout and App Bar

The app uses **Material Design** and a single main screen (`GameScreen`) with the following layout.

### 4.1 App Bar

- Title: **`"Gopher Hunt Game"`**
- Title is **centered**.
- Uses the app’s theme color (seeded from `Colors.brown`).

### 4.2 Top Control Row

A horizontal row with three buttons:

- **Start**
  - `ElevatedButton.icon` with `Icons.play_arrow`
  - Starts a new game if the game is not already running.
  - Resets the controller and both players, then enters the game loop.
- **Stop**
  - `ElevatedButton.icon` with `Icons.stop`
  - Stops the current game loop (no more moves are played).
- **Exit**
  - `ElevatedButton.icon` with `Icons.exit_to_app`
  - Calls `SystemNavigator.pop()` to close the app.

### 4.3 Status Section

Shown under the buttons as a vertical column:

1. `Status: Running` or `Status: Stopped` (bold).
2. `Current turn: <player-name>`  
   - Uses `AnimatedSwitcher` so the player name transitions smoothly.
3. `Gopher: (r, c)`  
   - Shows the current gopher location in `(row, col)` format.  
   - Visible to the user but not to the player classes.

## 5. Player Boards (Two 8×8 Tables)

Below the status section are two vertically stacked boards, one per player.

For **each player board**:

- A **title** above the grid:
  - Example: `Player 1 (Random Bot)` in blue,  
    `Player 2 (Heuristic Bot)` in green.
- An **8×8 grid** of square cells:
  - Implemented via `GridView.builder` with `crossAxisCount: 8`.
  - The grid is inside a square `SizedBox` so that cells are roughly the same width and height.

Each cell displays:

- **Background color** based on `CellState.result`:
  - `null` → light grey (not guessed)
  - `hit` → red-ish
  - `nearMiss` → orange-ish
  - `miss` → blue-grey-ish
- **Guess number** (`cell.guessNumber`) centered as text if that cell has been guessed.
- **Gopher icon**:
  - If `(row, col)` is the gopher location, a small `Icons.pets` icon is drawn.
  - The gopher position is shown on **both boards**.

**Animation:**

- Each cell is wrapped in an `AnimatedContainer` with a short duration.
- When the result or color changes, the cell transitions smoothly.

## 6. Guess Log (List Items Format)

At the bottom of the screen is a **scrollable log** of all guesses.

- Layout:
  - A `Container` with a border and rounded corners.
  - Inside, a `ListView.builder` with one **list item per guess**.

Each list item (`ListTile`) has the following format:

- **Background color**:
  - Light blue for guesses from Player 1.
  - Light green for guesses from Player 2.
- **Leading text**:  
  - `#<guessNumber>` (e.g., `#1`, `#2`, …)
- **Title**:  
  - `<playerName> guessed (r, c)`  
    Example: `Random Bot guessed (3, 5)`
- **Subtitle**:  
  - `Result: <Success | Near miss | Complete miss>`  
    These strings directly correspond to the feedback mapping:
    - `GuessResult.hit` → `"Success"`
    - `GuessResult.nearMiss` → `"Near miss"`
    - `GuessResult.miss` → `"Complete miss"`

This log shows the complete sequence of moves, in order, matching the numbered cells in the boards.

## 7. Timing and Async Behavior

- The main class runs the game loop as an **async** method.
- For each turn:
  1. Call `await currentPlayer.makeMove()`.
  2. Register the guess (`registerGuess`) and log it.
  3. Update the UI (`setState`).
  4. Wait **2 seconds**: `await Future.delayed(const Duration(seconds: 2));`
  5. If no winner yet, switch turns and repeat.
- Player `resetAsync()` methods are **called without `await`** when the game starts, as required by the spec.
