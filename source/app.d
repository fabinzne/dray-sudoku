// Std imports
import std.stdio;
import std.random;
import std.algorithm;
import std.conv;
import std.string;
import core.stdc.string : memset;

// Raylib
import raylib;

struct SudokuGame {
	int[9][9] board;
	int[9][9] solution;
	int[9][9] initial;
	bool[9][9] conflicts;

	// UI State
	int selectedRow = -1;
	int selectedCol = -1;
	bool gameWon = false;
	int difficulty = 40; // Number of cells to remove

	bool isValid(int row, int col, int num) {
		for (int i = 0; i < 9; ++i) {
			if (board[row][i] == num) return false;
		}

		for (int j = 0; j < 9; ++j) {
			if (board[j][col] == num) return false;
		}

		int boxRow = (row / 3) * 3;
		int boxCol = (col / 3) * 3;

		for (int i = boxRow; i < boxRow + 3; ++i) {
			for (int j = boxCol; j < boxCol + 3; ++j) {
				if (board[i][j] == num) return false;
			}
		}

		return true;
	}

	void generateBoard() {
      // Reset all arrays
		memset(board.ptr, 0, board.length * int.sizeof);
    memset(solution.ptr, 0, solution.length * int.sizeof);
    memset(initial.ptr, 0, initial.length * int.sizeof);
    memset(conflicts.ptr, 0, conflicts.length * bool.sizeof);
    
		gameWon = false;
		generateComplete();
    
		solution = board;
		
		removeNumbers();
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        initial[i][j] = board[i][j];
      }
    }
    updateConflicts();
  }

	void generateComplete() {
		int[9] nums = [1, 2, 3, 4, 5, 6, 7, 8, 9];
		
		fillBoard(0, 0, nums);
	}

	bool fillBoard(int row, int col, int[9] nums) {
		if (row == 9) return true;

		int nextRow = (col == 8) ? row + 1 : row;
		int nextCol = (col == 8) ? 0 : col + 1;

		auto rng = Random(unpredictableSeed);
		nums[].randomShuffle(rng);

		foreach (num; nums) {
			if (isValid(row, col, num)) {
				board[row][col] = num;

				if (fillBoard(nextRow, nextCol, nums)) {
					return true;
				}

				board[row][col] = 0;
			}
		}

		return false;
	}

	void removeNumbers() {
		auto rng = Random(unpredictableSeed);
		int removed = 0;

		while (removed < difficulty) {
			int row = uniform(0, 9, rng);
			int col = uniform(0, 9, rng);

			if (board[row][col] != 0) {
				int backup = board[row][col];
				board[row][col] = 0;

				if (hasUniqueSolution()) {
					removed++;
				} else {
					board[row][col] = backup;
				}
			}
		}
	}

	bool hasUniqueSolution() {
    int[9][9] temp = board;
    int solutions = 0;
    
		countSolutions(temp, 0, 0, solutions);
    
		return solutions == 1;
	}

	void countSolutions(ref int[9][9] grid, int row, int col, ref int solutions) {
		if (solutions > 1) return;

		if (row == 9) {
			solutions++;
			return;
		}

		int nextRow = (col == 8) ? row + 1 : row;
		int nextCol = (col == 8) ? 0 : col + 1;

		if (grid[row][col] != 0) {
			countSolutions(grid, nextRow, nextCol, solutions);
		} else {
			for (int num = 1; num <= 9; ++num) {
				if (isValidInGrid(grid, row, col, num)) {
					grid[row][col] = num;
					countSolutions(grid, nextRow, nextCol, solutions);
					grid[row][col] = 0;
				}
			}
		}
	}

  bool isValidInGrid(int[9][9] grid, int row, int col, int num) {
    for (int j = 0; j < 9; j++) if (grid[row][j] == num) return false;
    for (int i = 0; i < 9; i++) if (grid[i][col] == num) return false;

    int boxRow = (row / 3) * 3;
    int boxCol = (col / 3) * 3;
    for (int i = boxRow; i < boxRow + 3; i++) {
      for (int j = boxCol; j < boxCol + 3; j++) {
        if (grid[i][j] == num) return false;
      }
    }
    return true;
  }

  void draw() {
    ClearBackground(Colors.RAYWHITE);
    int cellSize = 60;
    int gridSize = cellSize * 9;
    int startX = (GetScreenWidth() - gridSize) / 2;
    int startY = 100;

    const(char)* title = "SUDOKU MASTER";
    int titleWidth = MeasureText(title, 40);
    DrawText(title, (GetScreenWidth() - titleWidth) / 2, 20, 40, Colors.DARKBLUE);

    for (int i = 0; i < 9; i++)
      for (int j = 0; j < 9; j++) {
        int x = startX + j * cellSize;
        int y = startY + i * cellSize;

        Color cellColor = Colors.WHITE;
        if (selectedRow == i && selectedCol == j) cellColor = Colors.LIGHTGRAY;
        else if (conflicts[i][j]) cellColor = Color(255,200,200,255);
        else if (initial[i][j] != 0) cellColor = Color(230,230,255,255);

        DrawRectangle(x,y,cellSize,cellSize,cellColor);
				DrawRectangleLines(x,y,cellSize,cellSize,Colors.BLACK);

        if (board[i][j] != 0) {
          string numStr = to!string(board[i][j]);
          const(char)* numCStr = toStringz(numStr);
          int numWidth = MeasureText(numCStr,30);
          Color textColor = initial[i][j] != 0 ? Colors.BLACK : Colors.BLUE;
          if (conflicts[i][j]) textColor = Colors.RED;
          DrawText(numCStr, x + (cellSize - numWidth)/2, y + (cellSize - 30)/2, 30, textColor);
        }
      }

			const(char)* instruction1 = "Click a cell and press 1-9 to enter numbers";
			const(char)* instruction2 = "Press DELETE/BACKSPACE to clear a cell";
			const(char)* instruction3 = "Press N for new game, H for hint, S to solve";
			DrawText(instruction1,startX,startY+gridSize+20,20,Colors.DARKGRAY);
			DrawText(instruction2,startX,startY+gridSize+45,20,Colors.DARKGRAY);
			DrawText(instruction3,startX,startY+gridSize+70,20,Colors.DARKGRAY);

      if (gameWon) {
        const(char)* winText = "CONGRATULATIONS! YOU WON!";
        int winWidth = MeasureText(winText,30);
        DrawText(winText,(GetScreenWidth()-winWidth)/2,startY+gridSize+110,30,Colors.GREEN);
      }

      if (IsKeyPressed(KeyboardKey.KEY_N)) {
        generateBoard();
        selectedRow = -1;
        selectedCol = -1;
      }
      if (IsKeyPressed(KeyboardKey.KEY_H) &&
        selectedRow >= 0 && selectedCol >= 0 &&
        initial[selectedRow][selectedCol] == 0 &&
        board[selectedRow][selectedCol] == 0) {
        board[selectedRow][selectedCol] = solution[selectedRow][selectedCol];
        updateConflicts();
      }
      if (IsKeyPressed(KeyboardKey.KEY_S)) {
        board = solution;
        updateConflicts();
      }
    }


	void handleInput() {
		Vector2 mousePos = GetMousePosition();

		if (IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) {
			int cellSize = 60;
			int gridSize = cellSize * 9;
			int startX = (GetScreenWidth() - gridSize) / 2;
			int startY = 100;

			if (mousePos.x >= startX && mousePos.x < startX + gridSize &&
					mousePos.y >= startY && mousePos.y < startY + gridSize) {
				
				selectedCol = cast(int)((mousePos.x - startX) / cellSize);
				selectedRow = cast(int)((mousePos.y - startY) / cellSize); 
			
			} else {
				selectedRow = -1;
				selectedCol = -1;
			}  
		}

		if (selectedRow >= 0 && selectedCol >= 0 && initial[selectedRow][selectedCol] == 0) { 
			for (int key = KeyboardKey.KEY_ONE; key <= KeyboardKey.KEY_NINE; key++) {
				if (IsKeyPressed(key)) {
          board[selectedRow][selectedCol] = key - KeyboardKey.KEY_ZERO;
          updateConflicts();
          break;
				}
			}
    
		if (IsKeyPressed(KeyboardKey.KEY_DELETE) ||
					IsKeyPressed(KeyboardKey.KEY_BACKSPACE) ||
					IsKeyPressed(KeyboardKey.KEY_ZERO)) {
						board[selectedRow][selectedCol] = 0;
						updateConflicts();
					}
		}
	}

	void updateConflicts() {
		memset(conflicts.ptr, 0, conflicts.length * bool.sizeof);

		for (int i = 0; i < 9; i++) {
			for (int j = 0; j < 9; j++) {
        if (board[i][j] != 0) {
          conflicts[i][j] = hasConflict(i, j);
				}
			}
    }
    
    checkWin();  // See if game is won
	}

	bool hasConflict(int row, int col) {
		int num = board[row][col];
		if (num == 0) return false;

		for (int i = 0; i < 9; ++i) {
			if (i != col && board[row][i] == num) return true;
		}

		for (int j = 0; j < 9; ++j) {
			if (j != row && board[j][col] == num) return true;
		}

    int boxRow = (row / 3) * 3;
    int boxCol = (col / 3) * 3;
    for (int i = boxRow; i < boxRow + 3; i++) {
      for (int j = boxCol; j < boxCol + 3; j++) {
        if ((i != row || j != col) && board[i][j] == num) {
          return true;
        }
      }
    }

		return false;
	} 

	void checkWin() {
		for (int i = 0; i < 9; ++i) {
			for (int j = 0; j < 9; ++j) {
				if (board[i][j] == 0 || conflicts[i][j]) {
					gameWon = false;
					return;
				}
			}
		}

		gameWon = true;
	}
}



void main()
{
	const int screenWidth = 800;
	const int screenHeight = 700;

	InitWindow(screenWidth, screenHeight, "Sudoku In Dlang");
	SetTargetFPS(60);

  SudokuGame game;
  game.generateBoard();

	while (!WindowShouldClose()) {
		game.handleInput();
		BeginDrawing();
		game.draw();
		EndDrawing();
	}

	CloseWindow();
}

