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
  int rows, cols;
  List<List<String>> grid;
  List<List<Color>> clr;
  List<List<Image?>> pieces = [];
  GameLoadedState(this.grid, this.clr, this.pieces, this.rows, this.cols);

  @override
  List<Object> get props => [grid, clr, pieces];
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
  int rows = 8, cols = 8, bombs = 0;
  List<List<String>> grid = [];
  List<List<Color>> clr = [];
  List<List<Image?>> pieces = [];

  List<int> startLoc = [], endLoc = [];
  bool play = false, start = false, end = false, block = false;
  final q = Queue<List<int>>();
  GameBloc() : super(GameLoadingState()) {
    on<LoadGameEvent>(
      (event, emit) {
        emit(GameLoadingState());
        grid = List.generate(rows, (_) => List.generate(cols, (x) => ' '));

        clr = List.generate(
            rows, (_) => List.generate(cols, (x) => Colors.white));

        pieces = List.generate(rows, (_) => List.generate(cols, (x) => null));

        var colors = [Colors.brown, Colors.white];
        var sel = 1;

        for (int i = 0; i < rows; i++) {
          for (int j = 0; j < cols; j++) {
            clr[i][j] = colors[sel];
            if (j < cols - 1) sel = 1 - sel;
          }
        }

        for (int j = 0; j < cols; j++) {
          pieces[1][j] = Image.asset('../assets/pieces/black_pawn.png');
          pieces[rows - 2][j] = Image.asset('../assets/pieces/white_pawn.png');

          if (j == 0 || j == cols - 1) {
            pieces[0][j] = Image.asset('../assets/pieces/black_rook.png');
            pieces[rows - 1][j] =
                Image.asset('../assets/pieces/white_rook.png');
          }
          if (j == 1 || j == cols - 2) {
            pieces[0][j] = Image.asset('../assets/pieces/black_horse.png');
            pieces[rows - 1][j] =
                Image.asset('../assets/pieces/white_horse.png');
          }
          if (j == 2 || j == cols - 3) {
            pieces[0][j] = Image.asset('../assets/pieces/black_bishop.png');
            pieces[rows - 1][j] =
                Image.asset('../assets/pieces/white_bishop.png');
          }
          if (j == 3) {
            pieces[0][j] = Image.asset('../assets/pieces/black_queen.png');
            pieces[rows - 1][j] =
                Image.asset('../assets/pieces/white_queen.png');
          }
          if (j == 4) {
            pieces[0][j] = Image.asset('../assets/pieces/black_king.png');
            pieces[rows - 1][j] =
                Image.asset('../assets/pieces/white_king.png');
          }
        }

        emit(GameLoadedState(grid, clr, pieces, rows, cols));
      },
    );

    on<SelectOptionEvent>(
      (event, emit) {
        emit(GameLoadingState());
        switch (event.e) {
          case 0:
            start = true;
            end = false;
            block = false;
            break;
          case 1:
            start = false;
            end = true;
            block = false;
            break;
          case 2:
            start = false;
            end = false;
            block = true;
            break;
        }

        emit(GameLoadedState(grid, clr, pieces, rows, cols));
      },
    );

    on<CellClickEvent>(
      (event, emit) {
        int i = event.i, j = event.j;

        emit(GameLoadedState(grid, clr, pieces, rows, cols));
      },
    );

    on<TogglePlayEvent>(
      (event, emit) async {
        emit(GameLoadedState(grid, clr, pieces, rows, cols));
      },
    );

    on<ResetGameEvent>(
      (event, emit) {
        play = false;
        add(LoadGameEvent());
      },
    );
  }
}
