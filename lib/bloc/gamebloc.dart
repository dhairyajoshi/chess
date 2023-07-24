// ignore_for_file: prefer_const_constructors

import 'dart:collection';
import 'dart:io';
import 'package:chess/bloc/appbloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GameLoadingState extends AppState {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class GameLoadedState extends AppState {
  int rows, cols, cur;
  List<List<String>> grid;
  List<List<Color>> clr;
  List<List<Image?>> pieces = [];
  GameLoadedState(
      this.grid, this.clr, this.pieces, this.cur, this.rows, this.cols);

  @override
  List<Object> get props => [grid, clr, cur, pieces];
}

class LoadGameEvent extends AppEvent {}

class ResetGameEvent extends AppEvent {}

class SelectOptionEvent extends AppEvent {
  int e;

  SelectOptionEvent(this.e);
}

class CellClickEvent extends AppEvent {
  int i, j;

  CellClickEvent(this.i, this.j);
}

class RandomizeEvent extends AppEvent {}

class TogglePlayEvent extends AppEvent {}

class GameBloc extends Bloc<AppEvent, AppState> {
  int rows = 8, cols = 8, cur = 0;
  List<List<String>> grid = [];
  List<List<Color>> clr = [], oclr = [];
  List<List<Image?>> pieces = [];
  List<List<int>> player = [];
  List<List<int>> available = [];
  List<int> selected = [];
  var colors = [Colors.brown, Colors.white];
  var sel = 1;

  Map<String, List<List<int>>> dirmap = {
    'pawn': [
      [-1, 0],
      [-2, 0],
    ],
    'rook': [
      [],
      [1, 0],
      [0, 1],
      [-1, 0],
      [0, -1]
    ],
    'horse': [
      [2, 1],
      [1, 2],
      [-2, 1],
      [-1, 2],
      [2, -1],
      [1, -2],
      [-2, -1],
      [-1, -2]
    ],
    'bishop': [
      [],
      [1, 1],
      [-1, -1],
      [-1, 1],
      [1, -1]
    ],
    'queen': [
      [],
      [1, 0],
      [0, 1],
      [-1, 0],
      [0, -1],
      [1, 1],
      [-1, -1],
      [-1, 1],
      [1, -1]
    ],
    'king': [
      [1, 0],
      [0, 1],
      [-1, 0],
      [0, -1],
      [1, 1],
      [-1, -1],
      [-1, 1],
      [1, -1]
    ]
  };

  bool corcheck(var x, var y) {
    return (x >= 0 && x < rows && y >= 0 && y < cols);
  }

  void spawn(int i, int j, Image piece) {
    int p;
    pieces[i][j] = piece;
    p = piece.image.toString().contains('black') ? 1 : 0;
    player[i][j] = p;
  }

  void despawn(int i, int j) {
    pieces[i][j] = null;
    player[i][j] = -1;
  }

  void flipboard() {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 8; j++) {
        var tpiece = pieces[i][j];
        pieces[i][j] = pieces[7 - i][j];
        pieces[7 - i][j] = tpiece;

        int p = player[i][j];
        player[i][j] = player[7 - i][j];
        player[7 - i][j] = p;
      }
    }
  }

  var blkpawn = Image.asset('../assets/pieces/black_pawn.png'),
      whtpawn = Image.asset('../assets/pieces/white_pawn.png'),
      blkrook = Image.asset('../assets/pieces/black_rook.png'),
      whtrook = Image.asset('../assets/pieces/white_rook.png'),
      blkhorse = Image.asset('../assets/pieces/black_horse.png'),
      whthorse = Image.asset('../assets/pieces/white_horse.png'),
      blkbishop = Image.asset('../assets/pieces/black_bishop.png'),
      whtbishop = Image.asset('../assets/pieces/white_bishop.png'),
      blkqueen = Image.asset('../assets/pieces/black_queen.png'),
      whtqueen = Image.asset('../assets/pieces/white_queen.png'),
      blkking = Image.asset('../assets/pieces/black_king.png'),
      whtking = Image.asset('../assets/pieces/white_king.png');

  List<int> startLoc = [], endLoc = [];
  bool play = false, start = false, end = false, block = false;
  final q = Queue<List<int>>();
  GameBloc() : super(GameLoadingState()) {
    on<LoadGameEvent>(
      (event, emit) {
        emit(GameLoadingState());
        grid = List.generate(rows, (_) => List.generate(cols, (x) => ' '));

        player = List.generate(rows, (_) => List.generate(cols, (x) => -1));

        available = List.generate(rows, (_) => List.generate(cols, (x) => 0));

        clr = List.generate(
            rows, (_) => List.generate(cols, (x) => Colors.white));

        oclr = List.generate(
            rows, (_) => List.generate(cols, (x) => Colors.white));

        pieces = List.generate(rows, (_) => List.generate(cols, (x) => null));

        for (int i = 0; i < rows; i++) {
          for (int j = 0; j < cols; j++) {
            clr[i][j] = colors[sel];
            if (j < cols - 1) sel = 1 - sel;
          }
        }

        // oclr = clr;

        for (int j = 0; j < cols; j++) {
          spawn(1, j, blkpawn);
          spawn(rows - 2, j, whtpawn);

          if (j == 0 || j == cols - 1) {
            spawn(0, j, blkrook);
            spawn(rows - 1, j, whtrook);
          }
          if (j == 1 || j == cols - 2) {
            spawn(0, j, blkhorse);
            spawn(rows - 1, j, whthorse);
          }
          if (j == 2 || j == cols - 3) {
            spawn(0, j, blkbishop);
            spawn(rows - 1, j, whtbishop);
          }
          if (j == 3) {
            spawn(0, j, blkqueen);
            spawn(rows - 1, j, whtqueen);
          }
          if (j == 4) {
            spawn(0, j, blkking);
            spawn(rows - 1, j, whtking);
          }
        }

        emit(GameLoadedState(grid, clr, pieces, cur, rows, cols));
      },
    );

    on<CellClickEvent>(
      (event, emit) {
        int i = event.i, j = event.j;

        var piece = pieces[i][j];
        if (player[i][j] == cur) {
          emit(GameLoadingState());
          available = List.generate(rows, (_) => List.generate(cols, (x) => 0));
          selected = [i, j];
          sel = 1;
          for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
              clr[r][c] = colors[sel];
              if (c < cols - 1) sel = 1 - sel;
            }
          }

          if (piece == blkpawn || piece == whtpawn) {
            var dirs = dirmap['pawn'];
            int len = i == rows - 2 ? 2 : 1;
            for (int x = 0; x < len; x++) {
              int ni = i + dirs![x][0], nj = j + dirs[x][1];
              if (corcheck(ni, nj) && player[ni][nj] == -1) {
                clr[ni][nj] = Color.fromARGB(255, 114, 255, 118);
                available[ni][nj] = 1;
              } else {
                break;
              }
            }
            if (corcheck(i - 1, j - 1) &&
                player[i - 1][j - 1] != player[i][j] &&
                player[i - 1][j - 1] != -1) {
              clr[i - 1][j - 1] = Colors.red;
              available[i - 1][j - 1] = 1;
            }
            if (corcheck(i - 1, j + 1) &&
                player[i - 1][j + 1] != player[i][j] &&
                player[i - 1][j + 1] != -1) {
              clr[i - 1][j + 1] = Colors.red;
              available[i - 1][j + 1] = 1;
            }
          } else if (piece == blkrook || piece == whtrook) {
            var dirs = dirmap['rook'];

            Queue<List<int>> q = Queue();
            q.addLast([i, j, 0]);

            while (q.isNotEmpty) {
              var x = q.first[0], y = q.first[1], d = q.first[2];
              q.removeFirst();

              if (d != 0) {
                int nx = x + dirs![d][0], ny = y + dirs[d][1];
                if (corcheck(nx, ny) && player[nx][ny] == -1) {
                  q.addLast([nx, ny, d]);
                  clr[nx][ny] = Color.fromARGB(255, 114, 255, 118);
                  available[nx][ny] = 1;
                } else if (corcheck(nx, ny) &&
                    player[nx][ny] != -1 &&
                    player[nx][ny] != player[i][j]) {
                  clr[nx][ny] = Colors.red;
                  available[nx][ny] = 1;
                }
              } else {
                for (int d = 1; d < dirs!.length; d++) {
                  int nx = x + dirs[d][0], ny = y + dirs[d][1];
                  if (corcheck(nx, ny) && player[nx][ny] == -1) {
                    q.addLast([nx, ny, d]);
                    clr[nx][ny] = Color.fromARGB(255, 114, 255, 118);
                    available[nx][ny] = 1;
                  } else if (corcheck(nx, ny) &&
                      player[nx][ny] != -1 &&
                      player[nx][ny] != player[i][j]) {
                    clr[nx][ny] = Colors.red;
                    available[nx][ny] = 1;
                  }
                }
              }
            }
          } else if (piece == blkhorse || piece == whthorse) {
            var dirs = dirmap['horse'];

            for (var dir in dirs!) {
              int ni = i + dir[0], nj = j + dir[1];
              if (corcheck(ni, nj) && player[ni][nj] != player[i][j]) {
                clr[ni][nj] = player[ni][nj] != -1
                    ? Colors.red
                    : Color.fromARGB(255, 114, 255, 118);
                available[ni][nj] = 1;
              }
            }
          } else if (piece == blkbishop || piece == whtbishop) {
            var dirs = dirmap['bishop'];

            Queue<List<int>> q = Queue();
            q.addLast([i, j, 0]);

            while (q.isNotEmpty) {
              var x = q.first[0], y = q.first[1], d = q.first[2];
              q.removeFirst();

              if (d != 0) {
                int nx = x + dirs![d][0], ny = y + dirs[d][1];
                if (corcheck(nx, ny) && player[nx][ny] == -1) {
                  q.addLast([nx, ny, d]);
                  clr[nx][ny] = Color.fromARGB(255, 114, 255, 118);
                  available[nx][ny] = 1;
                } else if (corcheck(nx, ny) &&
                    player[nx][ny] != -1 &&
                    player[nx][ny] != player[i][j]) {
                  clr[nx][ny] = Colors.red;
                  available[nx][ny] = 1;
                }
              } else {
                for (int d = 1; d < dirs!.length; d++) {
                  int nx = x + dirs[d][0], ny = y + dirs[d][1];
                  if (corcheck(nx, ny) && player[nx][ny] == -1) {
                    q.addLast([nx, ny, d]);
                    clr[nx][ny] = Color.fromARGB(255, 114, 255, 118);
                    available[nx][ny] = 1;
                  } else if (corcheck(nx, ny) &&
                      player[nx][ny] != -1 &&
                      player[nx][ny] != player[i][j]) {
                    clr[nx][ny] = Colors.red;
                    available[nx][ny] = 1;
                  }
                }
              }
            }
          } else if (piece == blkking || piece == whtking) {
            var dirs = dirmap['king'];
            for (var dir in dirs!) {
              int ni = i + dir[0], nj = j + dir[1];
              if (corcheck(ni, nj) && player[ni][nj] == -1) {
                clr[ni][nj] = Color.fromARGB(255, 114, 255, 118);
                available[ni][nj];
              } else if (corcheck(ni, nj) &&
                  player[ni][nj] != -1 &&
                  player[ni][nj] != player[i][j]) {
                clr[ni][nj] = Colors.red;
                available[ni][nj];
              }
            }
          } else if (piece == blkqueen || piece == whtqueen) {
            var dirs = dirmap['queen'];

            Queue<List<int>> q = Queue();
            q.addLast([i, j, 0]);

            while (q.isNotEmpty) {
              var x = q.first[0], y = q.first[1], d = q.first[2];
              q.removeFirst();

              if (d != 0) {
                int nx = x + dirs![d][0], ny = y + dirs[d][1];
                if (corcheck(nx, ny) && player[nx][ny] == -1) {
                  q.addLast([nx, ny, d]);
                  clr[nx][ny] = Color.fromARGB(255, 114, 255, 118);
                  available[nx][ny] = 1;
                } else if (corcheck(nx, ny) &&
                    player[nx][ny] != -1 &&
                    player[nx][ny] != player[i][j]) {
                  clr[nx][ny] = Colors.red;
                  available[nx][ny] = 1;
                }
              } else {
                for (int d = 1; d < dirs!.length; d++) {
                  int nx = x + dirs[d][0], ny = y + dirs[d][1];
                  if (corcheck(nx, ny) && player[nx][ny] == -1) {
                    q.addLast([nx, ny, d]);
                    clr[nx][ny] = Color.fromARGB(255, 114, 255, 118);
                    available[nx][ny] = 1;
                  } else if (corcheck(nx, ny) &&
                      player[nx][ny] != -1 &&
                      player[nx][ny] != player[i][j]) {
                    clr[nx][ny] = Colors.red;
                    available[nx][ny] = 1;
                  }
                }
              }
            }

            emit(GameLoadedState(grid, clr, pieces, cur, rows, cols));
          }
        } else if (available[i][j] == 1) {
          emit(GameLoadingState());
          int seli = selected[0], selj = selected[1];

          if (player[i][j] != -1) {
            despawn(i, j);
          }

          var piece = pieces[seli][selj];

          despawn(seli, selj);
          spawn(i, j, piece!);
          available = List.generate(rows, (_) => List.generate(cols, (x) => 0));
          selected = [];
          sel = 1;
          for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
              clr[r][c] = colors[sel];
              if (c < cols - 1) sel = 1 - sel;
            }
          }
          cur = 1 - cur;
          if (pieces[i][j]!.image.toString().contains('pawn') && i == 0) { 
            pieces[i][j] = 
                pieces[i][j]!.image.toString().contains('black') ? blkqueen : whtqueen;
          }
          flipboard();
          emit(GameLoadedState(grid, clr, pieces, cur, rows, cols));
        }

        emit(GameLoadedState(grid, clr, pieces, cur, rows, cols));
      },
    );

    on<TogglePlayEvent>(
      (event, emit) async {
        emit(GameLoadedState(grid, clr, pieces, cur, rows, cols));
      },
    );

    on<ResetGameEvent>(
      (event, emit) {
        play = false;
        cur = 0;
        add(LoadGameEvent());
      },
    );
  }
}
